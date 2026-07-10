import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { Patient, PatientDataPoint, PatientRecord, PatientAlert, PatientDiagnosis, PatientLabAlert } from '../model/Patient';

const DB_NAME: string = 'medcalc_patients.db';
const DB_VERSION: number = 5;
const DB_SECURITY: relationalStore.SecurityLevel = relationalStore.SecurityLevel.S3;

const CREATE_PATIENTS: string =
  'CREATE TABLE IF NOT EXISTS patients (' +
  'id TEXT PRIMARY KEY,' +
  'name TEXT NOT NULL,' +
  'bedNo TEXT,' +
  'age INTEGER,' +
  'sex TEXT,' +
  'note TEXT,' +
  'createdAt INTEGER NOT NULL,' +
  'updatedAt INTEGER NOT NULL)';

const CREATE_PATIENT_DATA: string =
  'CREATE TABLE IF NOT EXISTS patient_data (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
  'patientId TEXT NOT NULL,' +
  'fieldKey TEXT NOT NULL,' +
  'value TEXT NOT NULL,' +
  'source TEXT,' +
  'timestamp INTEGER NOT NULL,' +
  'examTime INTEGER DEFAULT 0,' +
  'note TEXT)';

const ALTER_ADD_EXAM_TIME: string =
  'ALTER TABLE patient_data ADD COLUMN examTime INTEGER DEFAULT 0';

const ALTER_ADD_SOURCE: string =
  'ALTER TABLE patient_diagnoses ADD COLUMN source TEXT DEFAULT \'rule\'';

const ALTER_ADD_MISSING: string =
  'ALTER TABLE patient_diagnoses ADD COLUMN missingCriteria TEXT DEFAULT \'\'';

const ALTER_ADD_SORTORDER: string =
  'ALTER TABLE patient_diagnoses ADD COLUMN sortOrder INTEGER DEFAULT 0';

const CREATE_PATIENT_RECORDS: string =
  'CREATE TABLE IF NOT EXISTS patient_records (' +
  'id TEXT PRIMARY KEY,' +
  'patientId TEXT NOT NULL,' +
  'type TEXT NOT NULL,' +
  'filePath TEXT,' +
  'textContent TEXT,' +
  'extractedJson TEXT,' +
  'timestamp INTEGER NOT NULL,' +
  'label TEXT)';

const CREATE_PATIENT_ALERTS: string =
  'CREATE TABLE IF NOT EXISTS patient_alerts (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
  'patientId TEXT NOT NULL,' +
  'calcId TEXT NOT NULL,' +
  'calcName TEXT NOT NULL,' +
  'completeness INTEGER,' +
  'resultJson TEXT,' +
  'triggeredAt INTEGER NOT NULL,' +
  'status TEXT DEFAULT \'active\')';

const IDX_DATA_PATIENT_FIELD: string =
  'CREATE INDEX IF NOT EXISTS idx_data_patient_field ON patient_data(patientId, fieldKey)';

const IDX_DATA_PATIENT_TS: string =
  'CREATE INDEX IF NOT EXISTS idx_data_patient_ts ON patient_data(patientId, fieldKey, timestamp DESC)';

const IDX_RECORDS_PATIENT: string =
  'CREATE INDEX IF NOT EXISTS idx_records_patient ON patient_records(patientId)';

const IDX_ALERTS_PATIENT_STATUS: string =
  'CREATE INDEX IF NOT EXISTS idx_alerts_patient_status ON patient_alerts(patientId, status)';

const CREATE_PATIENT_DIAGNOSES: string =
  'CREATE TABLE IF NOT EXISTS patient_diagnoses (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
  'patientId TEXT NOT NULL,' +
  'ruleId TEXT NOT NULL,' +
  'name TEXT NOT NULL,' +
  'category TEXT NOT NULL,' +
  'urgency TEXT NOT NULL,' +
  'source TEXT DEFAULT \'rule\',' +
  'missingCriteria TEXT DEFAULT \'\',' +
  'llmConfirmed INTEGER DEFAULT 0,' +
  'llmNote TEXT,' +
  'triggeredAt INTEGER NOT NULL,' +
  'sortOrder INTEGER DEFAULT 0,' +
  'status TEXT DEFAULT \'active\')';

const IDX_DIAGNOSES_PATIENT_STATUS: string =
  'CREATE INDEX IF NOT EXISTS idx_diagnoses_patient_status ON patient_diagnoses(patientId, status)';

const CREATE_PATIENT_LAB_ALERTS: string =
  'CREATE TABLE IF NOT EXISTS patient_lab_alerts (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
  'patientId TEXT NOT NULL,' +
  'ruleId TEXT NOT NULL,' +
  'name TEXT NOT NULL,' +
  'category TEXT NOT NULL,' +
  'urgency TEXT NOT NULL,' +
  'fieldKey TEXT,' +
  'fieldLabel TEXT,' +
  'value TEXT,' +
  'threshold TEXT,' +
  'unit TEXT,' +
  'description TEXT,' +
  'triggeredAt INTEGER NOT NULL,' +
  'status TEXT DEFAULT \'active\')';

const IDX_LAB_ALERTS_PATIENT_STATUS: string =
  'CREATE INDEX IF NOT EXISTS idx_lab_alerts_patient_status ON patient_lab_alerts(patientId, status)';

export class PatientRepository {
  private static instance: PatientRepository | null = null;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  private constructor() {}

  static getInstance(): PatientRepository {
    if (!PatientRepository.instance) {
      PatientRepository.instance = new PatientRepository();
    }
    return PatientRepository.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.initPromise) {
      return this.initPromise;
    }
    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  private async doInit(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: DB_SECURITY
    };
    this.store = await relationalStore.getRdbStore(context, config);
    const currentVersion = this.store.version;
    if (currentVersion < DB_VERSION) {
      if (currentVersion === 0) {
        await this.store.executeSql(CREATE_PATIENTS);
        await this.store.executeSql(CREATE_PATIENT_DATA);
        await this.store.executeSql(CREATE_PATIENT_RECORDS);
        await this.store.executeSql(CREATE_PATIENT_ALERTS);
        await this.store.executeSql(IDX_DATA_PATIENT_FIELD);
        await this.store.executeSql(IDX_DATA_PATIENT_TS);
        await this.store.executeSql(IDX_RECORDS_PATIENT);
        await this.store.executeSql(IDX_ALERTS_PATIENT_STATUS);
        await this.store.executeSql(CREATE_PATIENT_DIAGNOSES);
        await this.store.executeSql(IDX_DIAGNOSES_PATIENT_STATUS);
        await this.store.executeSql(CREATE_PATIENT_LAB_ALERTS);
        await this.store.executeSql(IDX_LAB_ALERTS_PATIENT_STATUS);
      }
      if (currentVersion >= 1 && currentVersion < 2) {
        await this.store.executeSql(ALTER_ADD_EXAM_TIME);
      }
      if (currentVersion >= 1 && currentVersion < 3) {
        await this.store.executeSql(ALTER_ADD_SOURCE);
        await this.store.executeSql(ALTER_ADD_MISSING);
      }
      if (currentVersion >= 1 && currentVersion < 4) {
        await this.store.executeSql(CREATE_PATIENT_LAB_ALERTS);
        await this.store.executeSql(IDX_LAB_ALERTS_PATIENT_STATUS);
      }
      if (currentVersion >= 1 && currentVersion < 5) {
        await this.store.executeSql(ALTER_ADD_SORTORDER);
      }
      this.store.version = DB_VERSION;
    }
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('PatientRepository not initialized');
    }
    return this.store;
  }

  async insertPatient(patient: Patient): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'id': patient.id,
      'name': patient.name,
      'bedNo': patient.bedNo,
      'age': patient.age,
      'sex': patient.sex,
      'note': patient.note,
      'createdAt': patient.createdAt,
      'updatedAt': patient.updatedAt
    };
    await db.insert('patients', bucket);
  }

  async queryPatients(keyword: string): Promise<Patient[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patients');
    if (keyword.length > 0) {
      predicates.like('name', '%' + keyword + '%')
        .or()
        .like('bedNo', '%' + keyword + '%');
    }
    predicates.orderByDesc('updatedAt');
    const rs = await db.query(predicates);
    const result: Patient[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const p = new Patient();
        p.id = rs.getString(rs.getColumnIndex('id'));
        p.name = rs.getString(rs.getColumnIndex('name'));
        p.bedNo = rs.getString(rs.getColumnIndex('bedNo'));
        p.age = rs.getLong(rs.getColumnIndex('age'));
        p.sex = rs.getString(rs.getColumnIndex('sex'));
        p.note = rs.getString(rs.getColumnIndex('note'));
        p.createdAt = rs.getLong(rs.getColumnIndex('createdAt'));
        p.updatedAt = rs.getLong(rs.getColumnIndex('updatedAt'));
        result.push(p);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async getPatientById(id: string): Promise<Patient | null> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patients');
    predicates.equalTo('id', id);
    const rs = await db.query(predicates);
    let result: Patient | null = null;
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const p = new Patient();
      p.id = rs.getString(rs.getColumnIndex('id'));
      p.name = rs.getString(rs.getColumnIndex('name'));
      p.bedNo = rs.getString(rs.getColumnIndex('bedNo'));
      p.age = rs.getLong(rs.getColumnIndex('age'));
      p.sex = rs.getString(rs.getColumnIndex('sex'));
      p.note = rs.getString(rs.getColumnIndex('note'));
      p.createdAt = rs.getLong(rs.getColumnIndex('createdAt'));
      p.updatedAt = rs.getLong(rs.getColumnIndex('updatedAt'));
      result = p;
    }
    rs.close();
    return result;
  }

  async updatePatient(patient: Patient): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'name': patient.name,
      'bedNo': patient.bedNo,
      'age': patient.age,
      'sex': patient.sex,
      'note': patient.note,
      'updatedAt': patient.updatedAt
    };
    const predicates = new relationalStore.RdbPredicates('patients');
    predicates.equalTo('id', patient.id);
    await db.update(bucket, predicates);
  }

  async deletePatient(id: string): Promise<void> {
    const db = this.ensureStore();
    const predData = new relationalStore.RdbPredicates('patient_data');
    predData.equalTo('patientId', id);
    await db.delete(predData);

    const predRec = new relationalStore.RdbPredicates('patient_records');
    predRec.equalTo('patientId', id);
    await db.delete(predRec);

    const predAlert = new relationalStore.RdbPredicates('patient_alerts');
    predAlert.equalTo('patientId', id);
    await db.delete(predAlert);

    const predPt = new relationalStore.RdbPredicates('patients');
    predPt.equalTo('id', id);
    await db.delete(predPt);
  }

  async insertDataPoint(dp: PatientDataPoint): Promise<number> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'patientId': dp.patientId,
      'fieldKey': dp.fieldKey,
      'value': dp.value,
      'source': dp.source,
      'timestamp': dp.timestamp,
      'examTime': dp.examTime,
      'note': dp.note
    };
    return await db.insert('patient_data', bucket);
  }

  async getLatestData(patientId: string): Promise<Map<string, string>> {
    const db = this.ensureStore();
    const result = new Map<string, string>();
    const sql =
      'SELECT fieldKey, value FROM patient_data ' +
      'WHERE patientId = ? AND timestamp = (' +
      '  SELECT MAX(timestamp) FROM patient_data pd2 ' +
      '  WHERE pd2.patientId = patient_data.patientId AND pd2.fieldKey = patient_data.fieldKey' +
      ')';
    const rs = await db.querySql(sql, [patientId]);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const key = rs.getString(0);
        const val = rs.getString(1);
        result.set(key, val);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async getLatestValue(patientId: string, fieldKey: string): Promise<string | null> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_data');
    predicates.equalTo('patientId', patientId)
      .equalTo('fieldKey', fieldKey)
      .orderByDesc('timestamp')
      .limitAs(1);
    const rs = await db.query(predicates);
    let result: string | null = null;
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      result = rs.getString(rs.getColumnIndex('value'));
    }
    rs.close();
    return result;
  }

  async getDataTimeline(patientId: string, fieldKey: string): Promise<PatientDataPoint[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_data');
    predicates.equalTo('patientId', patientId)
      .equalTo('fieldKey', fieldKey)
      .orderByDesc('timestamp');
    const rs = await db.query(predicates);
    const result: PatientDataPoint[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const dp = new PatientDataPoint();
        dp.id = rs.getLong(rs.getColumnIndex('id'));
        dp.patientId = rs.getString(rs.getColumnIndex('patientId'));
        dp.fieldKey = rs.getString(rs.getColumnIndex('fieldKey'));
        dp.value = rs.getString(rs.getColumnIndex('value'));
        dp.source = rs.getString(rs.getColumnIndex('source'));
        dp.timestamp = rs.getLong(rs.getColumnIndex('timestamp'));
        const examTimeIdx = rs.getColumnIndex('examTime');
        dp.examTime = examTimeIdx >= 0 ? rs.getLong(examTimeIdx) : 0;
        dp.note = rs.getString(rs.getColumnIndex('note'));
        result.push(dp);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async updateExamTime(dataPointId: number, examTime: number): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'examTime': examTime
    };
    const predicates = new relationalStore.RdbPredicates('patient_data');
    predicates.equalTo('id', dataPointId);
    await db.update(bucket, predicates);
  }

  async insertRecord(record: PatientRecord): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'id': record.id,
      'patientId': record.patientId,
      'type': record.type,
      'filePath': record.filePath,
      'textContent': record.textContent,
      'extractedJson': record.extractedJson,
      'timestamp': record.timestamp,
      'label': record.label
    };
    await db.insert('patient_records', bucket);
  }

  async getRecordsByPatient(patientId: string): Promise<PatientRecord[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_records');
    predicates.equalTo('patientId', patientId).orderByDesc('timestamp');
    const rs = await db.query(predicates);
    const result: PatientRecord[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const r = new PatientRecord();
        r.id = rs.getString(rs.getColumnIndex('id'));
        r.patientId = rs.getString(rs.getColumnIndex('patientId'));
        r.type = rs.getString(rs.getColumnIndex('type'));
        r.filePath = rs.getString(rs.getColumnIndex('filePath'));
        r.textContent = rs.getString(rs.getColumnIndex('textContent'));
        r.extractedJson = rs.getString(rs.getColumnIndex('extractedJson'));
        r.timestamp = rs.getLong(rs.getColumnIndex('timestamp'));
        r.label = rs.getString(rs.getColumnIndex('label'));
        result.push(r);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async deleteRecord(id: string): Promise<void> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_records');
    predicates.equalTo('id', id);
    await db.delete(predicates);
  }

  async deleteDataByNote(patientId: string, note: string): Promise<void> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_data');
    predicates.equalTo('patientId', patientId).equalTo('note', note);
    await db.delete(predicates);
  }

  async deleteDataByFieldKeys(patientId: string, fieldKeys: string[], timestamp: number): Promise<void> {
    const db = this.ensureStore();
    for (let i = 0; i < fieldKeys.length; i++) {
      const predicates = new relationalStore.RdbPredicates('patient_data');
      predicates.equalTo('patientId', patientId)
        .equalTo('fieldKey', fieldKeys[i])
        .equalTo('timestamp', timestamp);
      await db.delete(predicates);
    }
  }

  async getRecordById(id: string): Promise<PatientRecord | null> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_records');
    predicates.equalTo('id', id);
    const rs = await db.query(predicates);
    let result: PatientRecord | null = null;
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const r = new PatientRecord();
      r.id = rs.getString(rs.getColumnIndex('id'));
      r.patientId = rs.getString(rs.getColumnIndex('patientId'));
      r.type = rs.getString(rs.getColumnIndex('type'));
      r.filePath = rs.getString(rs.getColumnIndex('filePath'));
      r.textContent = rs.getString(rs.getColumnIndex('textContent'));
      r.extractedJson = rs.getString(rs.getColumnIndex('extractedJson'));
      r.timestamp = rs.getLong(rs.getColumnIndex('timestamp'));
      r.label = rs.getString(rs.getColumnIndex('label'));
      result = r;
    }
    rs.close();
    return result;
  }

  async getActiveAlerts(patientId: string): Promise<PatientAlert[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_alerts');
    predicates.equalTo('patientId', patientId)
      .equalTo('status', 'active')
      .orderByDesc('triggeredAt');
    const rs = await db.query(predicates);
    const result: PatientAlert[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const a = new PatientAlert();
        a.id = rs.getLong(rs.getColumnIndex('id'));
        a.patientId = rs.getString(rs.getColumnIndex('patientId'));
        a.calcId = rs.getString(rs.getColumnIndex('calcId'));
        a.calcName = rs.getString(rs.getColumnIndex('calcName'));
        a.completeness = rs.getLong(rs.getColumnIndex('completeness'));
        a.resultJson = rs.getString(rs.getColumnIndex('resultJson'));
        a.triggeredAt = rs.getLong(rs.getColumnIndex('triggeredAt'));
        a.status = rs.getString(rs.getColumnIndex('status'));
        result.push(a);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async upsertAlert(patientId: string, calcId: string, calcName: string, completeness: number, resultJson: string, triggeredAt: number): Promise<void> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_alerts');
    pred.equalTo('patientId', patientId).equalTo('calcId', calcId).equalTo('status', 'active');
    const rs = await db.query(pred);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const existingJson = rs.getString(rs.getColumnIndex('resultJson'));
      const existingId = rs.getLong(rs.getColumnIndex('id'));
      rs.close();
      if (existingJson === resultJson) {
        return;
      }
      const resolveBucket: ValuesBucket = { 'status': 'resolved' };
      const resolvePred = new relationalStore.RdbPredicates('patient_alerts');
      resolvePred.equalTo('id', existingId);
      await db.update(resolveBucket, resolvePred);
    } else {
      rs.close();
    }
    const bucket: ValuesBucket = {
      'patientId': patientId,
      'calcId': calcId,
      'calcName': calcName,
      'completeness': completeness,
      'resultJson': resultJson,
      'triggeredAt': triggeredAt,
      'status': 'active'
    };
    await db.insert('patient_alerts', bucket);
  }

  async resolveAlertsForCalc(patientId: string, calcId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_alerts');
    pred.equalTo('patientId', patientId).equalTo('calcId', calcId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async resolveAllAlerts(patientId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_alerts');
    pred.equalTo('patientId', patientId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async getAlertCount(patientId: string): Promise<number> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_alerts');
    predicates.equalTo('patientId', patientId).equalTo('status', 'active');
    const rs = await db.query(predicates);
    const count = rs.rowCount;
    rs.close();
    return count;
  }

  async getAllActiveAlertCount(): Promise<Map<string, number>> {
    const db = this.ensureStore();
    const result = new Map<string, number>();
    const sql = 'SELECT patientId, COUNT(*) as cnt FROM patient_alerts WHERE status = \'active\' GROUP BY patientId';
    const rs = await db.querySql(sql, []);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const pid = rs.getString(0);
        const cnt = rs.getLong(1);
        result.set(pid, cnt);
      } while (rs.goToNextRow());
    }
    rs.close();
    return result;
  }

  async upsertDiagnosis(patientId: string, ruleId: string, name: string, category: string,
    urgency: string, source: string, missingCriteria: string,
    llmConfirmed: number, llmNote: string, triggeredAt: number,
    sortOrder: number): Promise<number> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('patientId', patientId).equalTo('ruleId', ruleId).equalTo('status', 'active');
    const rs = await db.query(pred);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const existingId = rs.getLong(rs.getColumnIndex('id'));
      const existingConfirmed = rs.getLong(rs.getColumnIndex('llmConfirmed'));
      rs.close();
      const bucket: ValuesBucket = {
        'urgency': urgency,
        'source': source,
        'missingCriteria': missingCriteria,
        'triggeredAt': triggeredAt,
        'sortOrder': sortOrder
      };
      if (llmConfirmed > existingConfirmed) {
        bucket['llmConfirmed'] = llmConfirmed;
        bucket['llmNote'] = llmNote;
      }
      const updatePred = new relationalStore.RdbPredicates('patient_diagnoses');
      updatePred.equalTo('id', existingId);
      await db.update(bucket, updatePred);
      return existingId;
    }
    rs.close();
    const bucket: ValuesBucket = {
      'patientId': patientId,
      'ruleId': ruleId,
      'name': name,
      'category': category,
      'urgency': urgency,
      'source': source,
      'missingCriteria': missingCriteria,
      'llmConfirmed': llmConfirmed,
      'llmNote': llmNote,
      'triggeredAt': triggeredAt,
      'sortOrder': sortOrder,
      'status': 'active'
    };
    await db.insert('patient_diagnoses', bucket);
    return 0;
  }

  async resolveDiagnosesForRule(patientId: string, ruleId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('patientId', patientId).equalTo('ruleId', ruleId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async resolveAllDiagnoses(patientId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('patientId', patientId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async getActiveDiagnoses(patientId: string): Promise<PatientDiagnosis[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_diagnoses');
    predicates.equalTo('patientId', patientId).equalTo('status', 'active');
    predicates.orderByAsc('sortOrder');
    const rs = await db.query(predicates);
    const list: PatientDiagnosis[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const d = new PatientDiagnosis();
        d.id = rs.getLong(rs.getColumnIndex('id'));
        d.patientId = rs.getString(rs.getColumnIndex('patientId'));
        d.ruleId = rs.getString(rs.getColumnIndex('ruleId'));
        d.name = rs.getString(rs.getColumnIndex('name'));
        d.category = rs.getString(rs.getColumnIndex('category'));
        d.urgency = rs.getString(rs.getColumnIndex('urgency'));
        d.source = rs.getString(rs.getColumnIndex('source'));
        d.missingCriteria = rs.getString(rs.getColumnIndex('missingCriteria'));
        d.llmConfirmed = rs.getLong(rs.getColumnIndex('llmConfirmed'));
        d.llmNote = rs.getString(rs.getColumnIndex('llmNote'));
        d.triggeredAt = rs.getLong(rs.getColumnIndex('triggeredAt'));
        d.sortOrder = rs.getLong(rs.getColumnIndex('sortOrder'));
        d.status = rs.getString(rs.getColumnIndex('status'));
        list.push(d);
      } while (rs.goToNextRow());
    }
    rs.close();
    return list;
  }

  async updateDiagnosisLlmResult(id: number, llmConfirmed: number, llmNote: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'llmConfirmed': llmConfirmed,
      'llmNote': llmNote
    };
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('id', id);
    await db.update(bucket, pred);
  }

  async updateDiagnosisSortOrder(id: number, sortOrder: number): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'sortOrder': sortOrder
    };
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('id', id);
    await db.update(bucket, pred);
  }

  async getDiagnosisById(id: number): Promise<PatientDiagnosis | null> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_diagnoses');
    predicates.equalTo('id', id);
    const rs = await db.query(predicates);
    let result: PatientDiagnosis | null = null;
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const d = new PatientDiagnosis();
      d.id = rs.getLong(rs.getColumnIndex('id'));
      d.patientId = rs.getString(rs.getColumnIndex('patientId'));
      d.ruleId = rs.getString(rs.getColumnIndex('ruleId'));
      d.name = rs.getString(rs.getColumnIndex('name'));
      d.category = rs.getString(rs.getColumnIndex('category'));
      d.urgency = rs.getString(rs.getColumnIndex('urgency'));
      d.source = rs.getString(rs.getColumnIndex('source'));
      d.missingCriteria = rs.getString(rs.getColumnIndex('missingCriteria'));
      d.llmConfirmed = rs.getLong(rs.getColumnIndex('llmConfirmed'));
      d.llmNote = rs.getString(rs.getColumnIndex('llmNote'));
      d.triggeredAt = rs.getLong(rs.getColumnIndex('triggeredAt'));
      d.sortOrder = rs.getLong(rs.getColumnIndex('sortOrder'));
      d.status = rs.getString(rs.getColumnIndex('status'));
      result = d;
    }
    rs.close();
    return result;
  }

  async getDiagnosisCount(patientId: string): Promise<number> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_diagnoses');
    predicates.equalTo('patientId', patientId).equalTo('status', 'active');
    const rs = await db.query(predicates);
    const count = rs.rowCount;
    rs.close();
    return count;
  }

  async deleteDiagnosesByPatient(patientId: string): Promise<void> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('patientId', patientId);
    await db.delete(pred);
  }

  async deleteDiagnosis(id: number): Promise<void> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('id', id);
    await db.delete(pred);
  }

  async updateUserDiagnosis(id: number, name: string, category: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = {
      'name': name,
      'category': category
    };
    const pred = new relationalStore.RdbPredicates('patient_diagnoses');
    pred.equalTo('id', id);
    await db.update(bucket, pred);
  }

  async upsertLabAlert(patientId: string, ruleId: string, name: string, category: string,
    urgency: string, fieldKey: string, fieldLabel: string, value: string,
    threshold: string, unit: string, description: string, triggeredAt: number): Promise<void> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_lab_alerts');
    pred.equalTo('patientId', patientId).equalTo('ruleId', ruleId).equalTo('status', 'active');
    const rs = await db.query(pred);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      const existingId = rs.getLong(rs.getColumnIndex('id'));
      rs.close();
      const resolveBucket: ValuesBucket = { 'status': 'resolved' };
      const resolvePred = new relationalStore.RdbPredicates('patient_lab_alerts');
      resolvePred.equalTo('id', existingId);
      await db.update(resolveBucket, resolvePred);
    } else {
      rs.close();
    }
    const bucket: ValuesBucket = {
      'patientId': patientId,
      'ruleId': ruleId,
      'name': name,
      'category': category,
      'urgency': urgency,
      'fieldKey': fieldKey,
      'fieldLabel': fieldLabel,
      'value': value,
      'threshold': threshold,
      'unit': unit,
      'description': description,
      'triggeredAt': triggeredAt,
      'status': 'active'
    };
    await db.insert('patient_lab_alerts', bucket);
  }

  async resolveLabAlertsForRule(patientId: string, ruleId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_lab_alerts');
    pred.equalTo('patientId', patientId).equalTo('ruleId', ruleId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async resolveAllLabAlerts(patientId: string): Promise<void> {
    const db = this.ensureStore();
    const bucket: ValuesBucket = { 'status': 'resolved' };
    const pred = new relationalStore.RdbPredicates('patient_lab_alerts');
    pred.equalTo('patientId', patientId).equalTo('status', 'active');
    await db.update(bucket, pred);
  }

  async getActiveLabAlerts(patientId: string): Promise<PatientLabAlert[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('patient_lab_alerts');
    predicates.equalTo('patientId', patientId).equalTo('status', 'active').orderByDesc('triggeredAt');
    const rs = await db.query(predicates);
    const list: PatientLabAlert[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const a = new PatientLabAlert();
        a.id = rs.getLong(rs.getColumnIndex('id'));
        a.patientId = rs.getString(rs.getColumnIndex('patientId'));
        a.ruleId = rs.getString(rs.getColumnIndex('ruleId'));
        a.name = rs.getString(rs.getColumnIndex('name'));
        a.category = rs.getString(rs.getColumnIndex('category'));
        a.urgency = rs.getString(rs.getColumnIndex('urgency'));
        a.fieldKey = rs.getString(rs.getColumnIndex('fieldKey'));
        a.fieldLabel = rs.getString(rs.getColumnIndex('fieldLabel'));
        a.value = rs.getString(rs.getColumnIndex('value'));
        a.threshold = rs.getString(rs.getColumnIndex('threshold'));
        a.unit = rs.getString(rs.getColumnIndex('unit'));
        a.description = rs.getString(rs.getColumnIndex('description'));
        a.triggeredAt = rs.getLong(rs.getColumnIndex('triggeredAt'));
        a.status = rs.getString(rs.getColumnIndex('status'));
        list.push(a);
      } while (rs.goToNextRow());
    }
    rs.close();
    return list;
  }

  async deleteLabAlertsByPatient(patientId: string): Promise<void> {
    const db = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('patient_lab_alerts');
    pred.equalTo('patientId', patientId);
    await db.delete(pred);
  }
}
