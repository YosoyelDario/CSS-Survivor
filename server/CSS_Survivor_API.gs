const API_VERSION = "2026-10-22-sync4-admin";

const SHEETS = {
  jugadores: "Jugadores",
  intentos: "Intentos",
  respuestas: "Respuestas",
  ranking: "Ranking",
  preguntas: "Preguntas"
};

function setupSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const headers = {
    Jugadores: ["id_jugador", "correo", "alias", "fecha_registro", "ultima_actividad", "es_prueba", "oculto_ranking"],
    Intentos: ["id_intento", "id_jugador", "correo", "alias", "fecha", "nivel", "puntaje", "aciertos", "errores", "timeouts", "tiempo_total_seg", "vidas_restantes", "mejor_racha", "insignias", "resultado"],
    Respuestas: ["id_intento", "id_jugador", "correo", "alias", "fecha", "nivel", "zona", "id_pregunta", "pregunta", "tipo", "propiedad_css", "respuesta_jugador", "respuesta_correcta", "correcta", "timeout", "tiempo_respuesta_seg", "tiempo_maximo_seg", "vidas_restantes", "puntaje_actual"],
    Ranking: ["posicion", "id_jugador", "alias", "nivel_1", "nivel_2", "nivel_3", "puntaje_total", "insignias", "ultima_actualizacion"],
    Preguntas: ["id_pregunta", "nivel", "pregunta", "tipo", "propiedad_css", "veces_respondida", "aciertos", "errores", "timeouts", "porcentaje_acierto", "porcentaje_error", "tiempo_promedio_seg"]
  };

  Object.keys(headers).forEach(nombre => {
    let sheet = ss.getSheetByName(nombre);
    if (!sheet) sheet = ss.insertSheet(nombre);

    // Ranking cambió de esquema: si detectamos la versión antigua, limpiamos solo
    // sus filas calculadas. Se reconstruye cuando cada jugador pulse CONECTAR.
    if (nombre === SHEETS.ranking && sheet.getLastRow() > 1) {
      const currentHeader = sheet.getRange(1, 1, 1, headers[nombre].length).getDisplayValues()[0];
      const sameSchema = headers[nombre].every((value, index) => String(currentHeader[index] || "") === value);
      if (!sameSchema) {
        sheet.getRange(2, 1, sheet.getLastRow() - 1, Math.max(sheet.getLastColumn(), headers[nombre].length)).clearContent();
      }
    }

    sheet.getRange(1, 1, 1, headers[nombre].length).setValues([headers[nombre]]).setFontWeight("bold");
    sheet.setFrozenRows(1);
    if (nombre === SHEETS.intentos) migrateLegacyIntentRows(sheet);
  });
}

function doGet(e) {
  const action = e && e.parameter ? e.parameter.action : "";
  if (action === "ranking") {
    return jsonResponse({ ok: true, version: API_VERSION, ranking: getRanking() });
  }
  if (action === "status") {
    return jsonResponse({ ok: true, version: API_VERSION, message: "CSS Survivor API funcionando" });
  }
  return jsonResponse({ ok: true, version: API_VERSION, message: "CSS Survivor API funcionando" });
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);
    if (!e || !e.postData || !e.postData.contents) {
      return jsonResponse({ ok: false, error: "No se recibieron datos" });
    }

    const data = JSON.parse(e.postData.contents);
    const action = String(data.action || "");

    if (action === "admin_login") {
      return jsonResponse(adminLogin(String(data.password || "")));
    }

    if (action === "admin_list") {
      requireAdminToken(String(data.token || ""));
      return jsonResponse({ ok: true, players: getAdminPlayers() });
    }

    if (action === "admin_set_test") {
      requireAdminToken(String(data.token || ""));
      setPlayerFlag(String(data.id_jugador || ""), "es_prueba", Boolean(data.value));
      actualizarEstadisticasPreguntas();
      return jsonResponse({ ok: true, message: Boolean(data.value) ? "Cuenta marcada como prueba" : "Cuenta marcada como real" });
    }

    if (action === "admin_set_hidden") {
      requireAdminToken(String(data.token || ""));
      setPlayerFlag(String(data.id_jugador || ""), "oculto_ranking", Boolean(data.value));
      return jsonResponse({ ok: true, message: Boolean(data.value) ? "Jugador ocultado del ranking" : "Jugador visible nuevamente" });
    }

    if (action === "admin_delete_player") {
      requireAdminToken(String(data.token || ""));
      deletePlayerData(String(data.id_jugador || ""));
      return jsonResponse({ ok: true, message: "Datos del jugador eliminados" });
    }

    if (action === "sync_ranking") {
      syncRankingSnapshot(data.ranking || {});
      return jsonResponse({ ok: true, message: "Ranking sincronizado" });
    }

    if (action !== "guardar_intento") {
      return jsonResponse({ ok: false, error: "Acción desconocida" });
    }

    const result = guardarIntento(data);

    // El ranking NO se reconstruye desde Intentos. Se sincroniza desde los mejores
    // puntajes locales N1/N2/N3, por lo que un intento perdido no deja el total incompleto.
    if (data.ranking && data.ranking.id_jugador) {
      syncRankingSnapshot(data.ranking);
    }

    if (result.guardado && result.respuestasGuardadas) {
      actualizarEstadisticasPreguntas();
    }

    return jsonResponse({
      ok: true,
      duplicate: !result.guardado,
      respuestas_guardadas: Boolean(result.respuestasGuardadas),
      message: result.guardado
        ? (result.respuestasGuardadas
          ? "Intento guardado y respuestas incluidas en el análisis"
          : "Intento guardado como historial; las respuestas no se duplicaron")
        : "El intento ya estaba registrado; ranking actualizado igualmente"
    });
  } catch (error) {
    return jsonResponse({ ok: false, error: String(error) });
  } finally {
    try { lock.releaseLock(); } catch (_) {}
  }
}

function guardarIntento(data) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const intento = data.intento || {};
  const respuestas = data.respuestas || [];
  const idIntento = String(intento.id_intento || "");

  if (!idIntento) throw new Error("Falta id_intento");

  const intentosSheet = ss.getSheetByName(SHEETS.intentos);
  migrateLegacyIntentRows(intentosSheet);
  if (intentoYaExiste(intentosSheet, idIntento)) {
    return { guardado: false };
  }

  registrarJugador(intento);

  const idJugador = String(intento.id_jugador || intento.correo || "");
  const nivel = Number(intento.nivel || 0);
  const resultado = String(intento.resultado || "").toLowerCase();

  // Las respuestas detalladas se usan para investigación solo una vez por jugador y nivel:
  // el primer intento válido (completado o game_over). Los abandonos quedan en el historial,
  // pero no consumen ese primer intento pedagógico.
  const primerIntentoValido =
    esResultadoValido(resultado) &&
    !tieneIntentoValidoPrevio(intentosSheet, idJugador, nivel);

  intentosSheet.appendRow([
    idIntento,
    intento.id_jugador || "",
    intento.correo || "",
    intento.alias || "",
    intento.fecha || new Date(),
    intento.nivel || 0,
    intento.puntaje || 0,
    intento.aciertos || 0,
    intento.errores || 0,
    intento.timeouts || 0,
    intento.tiempo_total_seg || 0,
    intento.vidas_restantes || 0,
    intento.mejor_racha || 0,
    intento.insignias || "",
    intento.resultado || ""
  ]);

  let respuestasGuardadas = false;

  if (primerIntentoValido && respuestas.length > 0) {
    const rows = respuestas.map(r => [
      idIntento,
      intento.id_jugador || "",
      intento.correo || "",
      intento.alias || "",
      r.fecha || intento.fecha || new Date(),
      r.nivel || intento.nivel || 0,
      r.zona || "",
      r.id_pregunta || "",
      r.pregunta || "",
      r.tipo || "",
      r.propiedad_css || "",
      r.respuesta_jugador || "",
      r.respuesta_correcta || "",
      Boolean(r.correcta),
      Boolean(r.timeout),
      Number(r.tiempo_respuesta_seg || 0),
      Number(r.tiempo_maximo_seg || 0),
      Number(r.vidas_restantes || 0),
      Number(r.puntaje_actual || 0)
    ]);
    const respuestasSheet = ss.getSheetByName(SHEETS.respuestas);
    respuestasSheet.getRange(respuestasSheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
    respuestasGuardadas = true;
  }

  return { guardado: true, respuestasGuardadas };
}

// Corrige filas generadas por una versión de prueba que pudo desplazar J:O una columna.
// Solo actúa cuando encuentra un resultado válido en la columna P; las filas correctas no se tocan.
function migrateLegacyIntentRows(sheet) {
  if (!sheet || sheet.getLastRow() < 2 || sheet.getLastColumn() < 16) return;
  const rowCount = sheet.getLastRow() - 1;
  const legacy = sheet.getRange(2, 10, rowCount, 7).getValues(); // J:P
  let changed = false;

  for (let i = 0; i < legacy.length; i++) {
    const oldResult = String(legacy[i][6] || "").toLowerCase();
    if (oldResult === "completado" || oldResult === "game_over" || oldResult === "abandonado") {
      legacy[i] = [legacy[i][1], legacy[i][2], legacy[i][3], legacy[i][4], legacy[i][5], legacy[i][6], ""];
      changed = true;
    }
  }

  if (changed) sheet.getRange(2, 10, rowCount, 7).setValues(legacy);
}

function esResultadoValido(resultado) {
  return resultado === "completado" || resultado === "game_over";
}

function tieneIntentoValidoPrevio(sheet, idJugador, nivel) {
  if (!idJugador || nivel <= 0) return false;

  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return false;

  // B=id_jugador, F=nivel, O=resultado
  const rows = sheet.getRange(2, 2, lastRow - 1, 14).getValues();

  for (let i = 0; i < rows.length; i++) {
    const rowIdJugador = String(rows[i][0] || "");
    const rowNivel = Number(rows[i][4] || 0);
    const rowResultado = String(rows[i][13] || "").toLowerCase();

    if (
      rowIdJugador === idJugador &&
      rowNivel === nivel &&
      esResultadoValido(rowResultado)
    ) {
      return true;
    }
  }

  return false;
}

function intentoYaExiste(sheet, idIntento) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return false;
  const ids = sheet.getRange(2, 1, lastRow - 1, 1).getDisplayValues();
  return ids.some(row => String(row[0]) === idIntento);
}

function registrarJugador(intento) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEETS.jugadores);
  const idJugador = String(intento.id_jugador || "");
  if (!idJugador) return;

  const values = sheet.getDataRange().getValues();
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][0]) === idJugador) {
      sheet.getRange(i + 1, 2, 1, 4).setValues([[
        intento.correo || values[i][1],
        intento.alias || values[i][2],
        values[i][3] || new Date(),
        new Date()
      ]]);
      return;
    }
  }

  sheet.appendRow([idJugador, intento.correo || "", intento.alias || "", new Date(), new Date(), false, false]);
}

// Ranking competitivo: una sola fila por jugador con el mejor puntaje local de cada nivel.
// Se sincroniza como snapshot independiente de los intentos usados para investigación.
function syncRankingSnapshot(snapshot) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEETS.ranking);
  if (!sheet) throw new Error("No existe la hoja Ranking");

  ensureRankingSchema(sheet);

  const id = String(snapshot.id_jugador || "");
  if (!id) throw new Error("Falta id_jugador en ranking");

  const alias = String(snapshot.alias || "JUGADOR");
  registrarJugador({ id_jugador: id, correo: id, alias });
  const n1 = Math.max(0, Number(snapshot.nivel_1 || 0));
  const n2 = Math.max(0, Number(snapshot.nivel_2 || 0));
  const n3 = Math.max(0, Number(snapshot.nivel_3 || 0));
  const total = n1 + n2 + n3;
  const insignias = String(snapshot.insignias || "");

  const lastRow = sheet.getLastRow();
  const players = {};

  if (lastRow >= 2) {
    const rows = sheet.getRange(2, 1, lastRow - 1, 9).getValues();
    rows.forEach(row => {
      const playerId = String(row[1] || "");
      if (!playerId) return;
      players[playerId] = {
        id: playerId,
        alias: String(row[2] || "JUGADOR"),
        n1: Number(row[3] || 0),
        n2: Number(row[4] || 0),
        n3: Number(row[5] || 0),
        insignias: String(row[7] || ""),
        updated: row[8] || new Date()
      };
    });
  }

  players[id] = {
    id,
    alias,
    n1,
    n2,
    n3,
    insignias,
    updated: new Date()
  };

  const ranking = Object.values(players)
    .map(j => ({ ...j, total: Number(j.n1) + Number(j.n2) + Number(j.n3) }))
    .sort((a, b) => b.total - a.total || a.alias.localeCompare(b.alias));

  if (sheet.getLastRow() > 1) {
    sheet.getRange(2, 1, sheet.getLastRow() - 1, 9).clearContent();
  }

  if (ranking.length > 0) {
    const out = ranking.map((j, index) => [
      index + 1,
      j.id,
      j.alias,
      j.n1,
      j.n2,
      j.n3,
      j.total,
      j.insignias,
      j.updated
    ]);
    sheet.getRange(2, 1, out.length, 9).setValues(out);
  }
}

function ensureRankingSchema(sheet) {
  const expected = ["posicion", "id_jugador", "alias", "nivel_1", "nivel_2", "nivel_3", "puntaje_total", "insignias", "ultima_actualizacion"];
  const current = sheet.getRange(1, 1, 1, expected.length).getDisplayValues()[0];
  const same = expected.every((value, index) => String(current[index] || "") === value);
  if (!same) {
    if (sheet.getLastRow() > 1) {
      sheet.getRange(2, 1, sheet.getLastRow() - 1, Math.max(sheet.getLastColumn(), expected.length)).clearContent();
    }
    sheet.getRange(1, 1, 1, expected.length).setValues([expected]).setFontWeight("bold");
    sheet.setFrozenRows(1);
  }
}

function actualizarEstadisticasPreguntas() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const respuestasSheet = ss.getSheetByName(SHEETS.respuestas);
  const preguntasSheet = ss.getSheetByName(SHEETS.preguntas);
  const rows = respuestasSheet.getDataRange().getValues();
  const stats = {};
  const flags = getPlayerFlagsMap();

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const idJugador = String(row[1] || "");
    if (flags[idJugador] && flags[idJugador].es_prueba) continue;
    const nivel = Number(row[5] || 0);
    const idPregunta = String(row[7] || "");
    if (!idPregunta) continue;

    if (!stats[idPregunta]) {
      stats[idPregunta] = {
        id: idPregunta,
        nivel,
        pregunta: String(row[8] || ""),
        tipo: String(row[9] || ""),
        propiedad: String(row[10] || ""),
        total: 0,
        aciertos: 0,
        errores: 0,
        timeouts: 0,
        sumaTiempos: 0
      };
    }

    const correcta = row[13] === true;
    const timeout = row[14] === true;
    stats[idPregunta].total++;
    stats[idPregunta].sumaTiempos += Number(row[15] || 0);
    if (correcta) stats[idPregunta].aciertos++; else stats[idPregunta].errores++;
    if (timeout) stats[idPregunta].timeouts++;
  }

  if (preguntasSheet.getLastRow() > 1) {
    preguntasSheet.getRange(2, 1, preguntasSheet.getLastRow() - 1, 12).clearContent();
  }

  const out = Object.values(stats).map(s => [
    s.id,
    s.nivel,
    s.pregunta,
    s.tipo,
    s.propiedad,
    s.total,
    s.aciertos,
    s.errores,
    s.timeouts,
    s.total > 0 ? (s.aciertos / s.total) * 100 : 0,
    s.total > 0 ? (s.errores / s.total) * 100 : 0,
    s.total > 0 ? s.sumaTiempos / s.total : 0
  ]);

  if (out.length > 0) {
    preguntasSheet.getRange(2, 1, out.length, 12).setValues(out);
  }
}

function getRanking() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEETS.ranking);
  ensureRankingSchema(sheet);
  const rows = sheet.getDataRange().getValues();
  const flags = getPlayerFlagsMap();
  const ranking = [];

  for (let i = 1; i < rows.length; i++) {
    const id = String(rows[i][1] || "");
    if (!id || !rows[i][2]) continue;
    const state = flags[id] || { es_prueba: false, oculto_ranking: false };
    if (state.es_prueba || state.oculto_ranking) continue;
    ranking.push({
      alias: String(rows[i][2] || "JUGADOR"),
      nivel_1: Number(rows[i][3] || 0),
      nivel_2: Number(rows[i][4] || 0),
      nivel_3: Number(rows[i][5] || 0),
      puntaje: Number(rows[i][6] || 0),
      insignias: String(rows[i][7] || "")
    });
  }

  ranking.sort((a, b) => b.puntaje - a.puntaje || a.alias.localeCompare(b.alias));
  return ranking.slice(0, 10).map((row, index) => ({ posicion: index + 1, ...row }));
}

// --- ADMINISTRACIÓN DEL PILOTO ---
// Ejecuta setupAdmin() UNA VEZ desde Apps Script. Genera una contraseña aleatoria,
// la guarda en Script Properties y la muestra en el registro de ejecución.
function setupAdmin() {
  const props = PropertiesService.getScriptProperties();
  let password = props.getProperty("ADMIN_PASSWORD");
  if (!password) {
    const raw = Utilities.getUuid().replace(/-/g, "");
    password = "CSS-" + raw.substring(0, 14);
    props.setProperty("ADMIN_PASSWORD", password);
  }
  Logger.log("Contraseña admin CSS Survivor: " + password);
  return password;
}

function adminLogin(password) {
  const expected = PropertiesService.getScriptProperties().getProperty("ADMIN_PASSWORD");
  if (!expected) {
    return { ok: false, error: "Administrador no configurado. Ejecuta setupAdmin() en Apps Script." };
  }
  if (!password || password !== expected) {
    Utilities.sleep(350);
    return { ok: false, error: "Contraseña de administrador incorrecta." };
  }

  const token = Utilities.getUuid();
  CacheService.getScriptCache().put("admin:" + token, "1", 1800);
  return { ok: true, token, message: "Acceso administrador concedido" };
}

function requireAdminToken(token) {
  if (!token || CacheService.getScriptCache().get("admin:" + token) !== "1") {
    throw new Error("Sesión de administrador vencida. Vuelve a iniciar sesión.");
  }
  // Renueva la sesión mientras se está usando.
  CacheService.getScriptCache().put("admin:" + token, "1", 1800);
}

function getPlayerFlagsMap() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEETS.jugadores);
  const map = {};
  if (!sheet || sheet.getLastRow() < 2) return map;
  const rows = sheet.getRange(2, 1, sheet.getLastRow() - 1, 7).getValues();
  rows.forEach(row => {
    const id = String(row[0] || "");
    if (!id) return;
    map[id] = {
      es_prueba: row[5] === true || String(row[5]).toLowerCase() === "true",
      oculto_ranking: row[6] === true || String(row[6]).toLowerCase() === "true"
    };
  });
  return map;
}

function getAdminPlayers() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const players = {};
  const jugadores = ss.getSheetByName(SHEETS.jugadores);
  const ranking = ss.getSheetByName(SHEETS.ranking);

  if (jugadores && jugadores.getLastRow() >= 2) {
    const rows = jugadores.getRange(2, 1, jugadores.getLastRow() - 1, 7).getValues();
    rows.forEach(row => {
      const id = String(row[0] || "");
      if (!id) return;
      players[id] = {
        id_jugador: id,
        correo: String(row[1] || ""),
        alias: String(row[2] || "JUGADOR"),
        es_prueba: row[5] === true || String(row[5]).toLowerCase() === "true",
        oculto_ranking: row[6] === true || String(row[6]).toLowerCase() === "true",
        nivel_1: 0,
        nivel_2: 0,
        nivel_3: 0,
        puntaje: 0
      };
    });
  }

  if (ranking && ranking.getLastRow() >= 2) {
    const rows = ranking.getRange(2, 1, ranking.getLastRow() - 1, 9).getValues();
    rows.forEach(row => {
      const id = String(row[1] || "");
      if (!id) return;
      if (!players[id]) {
        players[id] = {
          id_jugador: id,
          correo: id,
          alias: String(row[2] || "JUGADOR"),
          es_prueba: false,
          oculto_ranking: false,
          nivel_1: 0,
          nivel_2: 0,
          nivel_3: 0,
          puntaje: 0
        };
      }
      players[id].alias = String(row[2] || players[id].alias);
      players[id].nivel_1 = Number(row[3] || 0);
      players[id].nivel_2 = Number(row[4] || 0);
      players[id].nivel_3 = Number(row[5] || 0);
      players[id].puntaje = Number(row[6] || 0);
    });
  }

  return Object.values(players).sort((a, b) => b.puntaje - a.puntaje || a.alias.localeCompare(b.alias));
}

function ensurePlayerRow(idJugador) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEETS.jugadores);
  if (!idJugador) throw new Error("Falta id_jugador");
  const rows = sheet.getDataRange().getValues();
  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0] || "") === idJugador) return i + 1;
  }

  let alias = "JUGADOR";
  const ranking = ss.getSheetByName(SHEETS.ranking);
  if (ranking && ranking.getLastRow() >= 2) {
    const rankRows = ranking.getRange(2, 2, ranking.getLastRow() - 1, 2).getValues();
    for (const row of rankRows) {
      if (String(row[0] || "") === idJugador) {
        alias = String(row[1] || alias);
        break;
      }
    }
  }

  sheet.appendRow([idJugador, idJugador, alias, new Date(), new Date(), false, false]);
  return sheet.getLastRow();
}

function setPlayerFlag(idJugador, field, value) {
  if (field !== "es_prueba" && field !== "oculto_ranking") throw new Error("Flag de jugador inválido");
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEETS.jugadores);
  const row = ensurePlayerRow(idJugador);
  const column = field === "es_prueba" ? 6 : 7;
  sheet.getRange(row, column).setValue(Boolean(value));
  sheet.getRange(row, 5).setValue(new Date());
}

function deletePlayerData(idJugador) {
  if (!idJugador) throw new Error("Falta id_jugador");
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  deleteRowsByValue(ss.getSheetByName(SHEETS.jugadores), 1, idJugador);
  deleteRowsByValue(ss.getSheetByName(SHEETS.intentos), 2, idJugador);
  deleteRowsByValue(ss.getSheetByName(SHEETS.respuestas), 2, idJugador);
  deleteRowsByValue(ss.getSheetByName(SHEETS.ranking), 2, idJugador);
  renumberRanking();
  actualizarEstadisticasPreguntas();
}

function deleteRowsByValue(sheet, column, expected) {
  if (!sheet || sheet.getLastRow() < 2) return;
  const values = sheet.getRange(2, column, sheet.getLastRow() - 1, 1).getDisplayValues();
  for (let i = values.length - 1; i >= 0; i--) {
    if (String(values[i][0] || "") === expected) sheet.deleteRow(i + 2);
  }
}

function renumberRanking() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEETS.ranking);
  if (!sheet || sheet.getLastRow() < 2) return;
  const rows = sheet.getRange(2, 1, sheet.getLastRow() - 1, 9).getValues();
  rows.sort((a, b) => Number(b[6] || 0) - Number(a[6] || 0) || String(a[2] || "").localeCompare(String(b[2] || "")));
  rows.forEach((row, index) => row[0] = index + 1);
  sheet.getRange(2, 1, rows.length, 9).setValues(rows);
}

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(ContentService.MimeType.JSON);
}
