#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

function printHelp() {
  process.stdout.write(`使い方:
  node scripts/later_holiday_reminder.mjs --input "あとで レポートを書く" [options]

オプション:
  --input             「あとで ...」形式の入力文
  --title             リマインダータイトルを直接指定（--inputより優先）
  --account           gog用Googleアカウント
  --calendar-id       対象カレンダーID (default: primary)
  --from              休み検索開始日 YYYY-MM-DD (default: 今日)
  --to                休み検索終了日 YYYY-MM-DD (default: 今日+120日)
  --list              Apple Remindersリスト名（省略時はデフォルト）
  --event-types       休み判定eventTypeをカンマ区切り指定
  --summary-keywords  件名キーワードをカンマ区切り指定
  --work-keywords     「この予定がある日は休みではない」とみなす件名キーワード（カンマ区切り）
  --due-time          追加時刻 HH:mm (default: 14:00)
  --fixed-spacing     学習間隔を使わず固定間隔（分）を使う
  --profile           学習プロファイルJSONパス
  --all-day-only      終日イベントのみ休み扱い
  --apply             実際にリマインダー追加
  --dry-run           追加せず計画のみ表示（default）
  -h, --help          このヘルプを表示
`);
}

function parseArgs(argv) {
  const today = todayYmd();
  const opts = {
    input: '',
    title: '',
    account: '',
    calendarId: 'primary',
    from: today,
    to: addDaysYmd(today, 120),
    list: '',
    eventTypes: ['outofoffice'],
    summaryKeywords: ['休み', '休日', '有給', 'off', 'vacation'],
    workKeywords: ['研究室'],
    dueTime: '14:00',
    fixedSpacing: 0,
    profilePath: defaultProfilePath(),
    allDayOnly: false,
    apply: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--input') {
      opts.input = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--title') {
      opts.title = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--account') {
      opts.account = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--calendar-id') {
      opts.calendarId = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--from') {
      opts.from = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--to') {
      opts.to = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--list') {
      opts.list = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--event-types') {
      opts.eventTypes = parseCsv(argv[i + 1]).map((v) => v.toLowerCase());
      i += 1;
      continue;
    }
    if (arg === '--summary-keywords') {
      opts.summaryKeywords = parseCsv(argv[i + 1]).map((v) => v.toLowerCase());
      i += 1;
      continue;
    }
    if (arg === '--work-keywords') {
      opts.workKeywords = parseCsv(argv[i + 1]).map((v) => v.toLowerCase());
      i += 1;
      continue;
    }
    if (arg === '--due-time') {
      opts.dueTime = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--fixed-spacing') {
      opts.fixedSpacing = Number.parseInt(argv[i + 1] ?? '', 10);
      i += 1;
      continue;
    }
    if (arg === '--profile') {
      opts.profilePath = argv[i + 1] ?? '';
      i += 1;
      continue;
    }
    if (arg === '--all-day-only') {
      opts.allDayOnly = true;
      continue;
    }
    if (arg === '--apply') {
      opts.apply = true;
      continue;
    }
    if (arg === '--dry-run') {
      opts.apply = false;
      continue;
    }
    if (arg === '-h' || arg === '--help') {
      printHelp();
      process.exit(0);
    }
    throw new Error(`未対応オプション: ${arg}`);
  }

  if (!opts.title && !opts.input) {
    throw new Error('--input または --title のどちらかが必要です。');
  }

  validateYmd(opts.from, '--from');
  validateYmd(opts.to, '--to');
  if (opts.from > opts.to) {
    throw new Error('--from は --to 以下である必要があります。');
  }
  validateHm(opts.dueTime, '--due-time');
  if (!Number.isFinite(opts.fixedSpacing) || opts.fixedSpacing < 0) {
    throw new Error('--fixed-spacing は 0 以上の整数で指定してください。');
  }

  return opts;
}

function parseCsv(value) {
  if (!value) return [];
  return String(value)
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
}

function todayYmd() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function addDaysYmd(ymd, days) {
  const date = new Date(`${ymd}T00:00:00`);
  date.setDate(date.getDate() + days);
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function validateYmd(ymd, label) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(ymd))) {
    throw new Error(`${label} は YYYY-MM-DD 形式で指定してください。`);
  }
}

function validateHm(hm, label) {
  if (!/^\d{2}:\d{2}$/.test(String(hm))) {
    throw new Error(`${label} は HH:mm 形式で指定してください。`);
  }
  const [hh, mm] = String(hm).split(':').map((v) => Number.parseInt(v, 10));
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) {
    throw new Error(`${label} の時刻が不正です。`);
  }
}

function defaultProfilePath() {
  return path.join(
    os.homedir(),
    'Library',
    'Application Support',
    'gogcli',
    'later-holiday-reminder-profile.json',
  );
}

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function sleepMilliseconds(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function runJsonCommand(command, args, { retryMach4099 = false } = {}) {
  const delays = [500, 1000, 2000];
  let lastError = null;

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const stdout = execFileSync(command, args, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 120000,
      });
      if (!stdout.trim()) return null;
      return JSON.parse(stdout);
    } catch (error) {
      lastError = error;
      const stderr = error?.stderr?.toString?.() ?? '';
      const isMach4099 = /Mach error 4099/i.test(stderr);
      if (retryMach4099 && isMach4099 && attempt < 3) {
        sleepMilliseconds(delays[attempt - 1]);
        continue;
      }
      if (!retryMach4099 || attempt >= 3 || !isMach4099) {
        break;
      }
    }
  }

  const stderr = lastError?.stderr?.toString?.() ?? String(lastError);
  const stdout = lastError?.stdout?.toString?.() ?? '';
  throw new Error(`${command} 実行失敗: ${args.join(' ')}\n${[stderr.trim(), stdout.trim()].filter(Boolean).join('\n')}`);
}

function runTextCommand(command, args, { retryMach4099 = false } = {}) {
  const delays = [500, 1000, 2000];
  let lastError = null;

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      return execFileSync(command, args, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 120000,
      }).trim();
    } catch (error) {
      lastError = error;
      const stderr = error?.stderr?.toString?.() ?? '';
      const isMach4099 = /Mach error 4099/i.test(stderr);
      if (retryMach4099 && isMach4099 && attempt < 3) {
        sleepMilliseconds(delays[attempt - 1]);
        continue;
      }
      if (!retryMach4099 || attempt >= 3 || !isMach4099) {
        break;
      }
    }
  }

  const stderr = lastError?.stderr?.toString?.() ?? String(lastError);
  const stdout = lastError?.stdout?.toString?.() ?? '';
  throw new Error(`${command} 実行失敗: ${args.join(' ')}\n${[stderr.trim(), stdout.trim()].filter(Boolean).join('\n')}`);
}

function runGogJson(rawArgs, account) {
  const args = [...rawArgs, '--json', '--results-only'];
  if (account) args.push('--account', account);
  if (process.env.GOG_NO_INPUT === '1') args.push('--no-input');
  return runJsonCommand('gog', args);
}

function runRemindctlJson(rawArgs) {
  const args = [...rawArgs, '--json'];
  if (process.env.REMINDCTL_NO_INPUT === '1' || process.env.GOG_NO_INPUT === '1') {
    args.push('--no-input');
  }
  return runJsonCommand('remindctl', args, { retryMach4099: true });
}

function runRemindctlText(rawArgs, { retryMach4099 = false } = {}) {
  const args = [...rawArgs];
  if (process.env.REMINDCTL_NO_INPUT === '1' || process.env.GOG_NO_INPUT === '1') {
    args.push('--no-input');
  }
  return runTextCommand('remindctl', args, { retryMach4099 });
}

function asArray(value) {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== 'object') return [];

  const candidates = ['items', 'results', 'events', 'tasks', 'taskLists', 'calendars', 'filters', 'labels'];
  for (const key of candidates) {
    if (Array.isArray(value[key])) return value[key];
  }
  return [];
}

function extractTaskTitle(input, titleOption) {
  if (titleOption && String(titleOption).trim()) return String(titleOption).trim();

  const raw = String(input ?? '').trim();
  if (!raw) throw new Error('入力文が空です。');

  const matched = raw.match(/^(あとで|後で)\s*(.+)$/);
  let body = matched ? matched[2] : raw;
  body = body
    .replace(/\s*(をやる|をする|する|やる|します|したい)$/, '')
    .trim();

  if (!body) {
    throw new Error('タスクタイトルを抽出できませんでした。');
  }
  return body;
}

function isAllDayEvent(event) {
  return Boolean(event?.start?.date && !event?.start?.dateTime);
}

function extractDateKey(value) {
  if (!value) return '';
  const raw = String(value);
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw;

  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return '';
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function isHolidayEvent(event, options) {
  if (!event || event.status === 'cancelled') return false;
  if (options.allDayOnly && !isAllDayEvent(event)) return false;

  const eventType = String(event.eventType ?? '').toLowerCase();
  const summary = String(event.summary ?? '').toLowerCase();

  const typeMatched = options.eventTypes.length > 0 && options.eventTypes.includes(eventType);
  const summaryMatched =
    options.summaryKeywords.length > 0 && options.summaryKeywords.some((keyword) => summary.includes(keyword));

  return typeMatched || summaryMatched;
}

function isWorkScheduledEvent(event, options) {
  if (!event || event.status === 'cancelled') return false;
  const summary = String(event.summary ?? '').toLowerCase();
  return options.workKeywords.length > 0 && options.workKeywords.some((keyword) => summary.includes(keyword));
}

function iterateDateRange(fromYmd, toYmd) {
  const out = [];
  let current = new Date(`${fromYmd}T00:00:00`);
  const end = new Date(`${toYmd}T00:00:00`);
  while (current <= end) {
    const y = current.getFullYear();
    const m = String(current.getMonth() + 1).padStart(2, '0');
    const d = String(current.getDate()).padStart(2, '0');
    out.push(`${y}-${m}-${d}`);
    current.setDate(current.getDate() + 1);
  }
  return out;
}

function pickNextHolidayDate(events, options) {
  const today = todayYmd();
  const holidayDates = new Set();
  const workScheduledDates = new Set();

  for (const event of asArray(events)) {
    const dateKey = extractDateKey(event?.start?.date ?? event?.start?.dateTime);
    if (!dateKey) continue;
    if (isHolidayEvent(event, options)) holidayDates.add(dateKey);
    if (isWorkScheduledEvent(event, options)) workScheduledDates.add(dateKey);
  }

  const start = options.from >= today ? options.from : today;
  for (const dateKey of iterateDateRange(start, options.to)) {
    if (holidayDates.has(dateKey) || !workScheduledDates.has(dateKey)) {
      return dateKey;
    }
  }
  return '';
}

function parseHmToMinutes(hm) {
  const [hh, mm] = String(hm).split(':').map((v) => Number.parseInt(v, 10));
  return hh * 60 + mm;
}

function minutesToHm(totalMinutes) {
  const mins = clamp(totalMinutes, 0, 23 * 60 + 45);
  const hh = String(Math.floor(mins / 60)).padStart(2, '0');
  const mm = String(mins % 60).padStart(2, '0');
  return `${hh}:${mm}`;
}

function extractDueLocalDateAndMinute(value) {
  if (!value) return null;
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) return null;
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return {
    ymd: `${y}-${m}-${d}`,
    minute: date.getHours() * 60 + date.getMinutes(),
  };
}

function estimateTaskMinutes(text) {
  const raw = String(text ?? '');

  const hourMatch = raw.match(/(\d+(?:\.\d+)?)\s*(時間|h|hr|hrs|hour|hours)/i);
  if (hourMatch) {
    const hours = Number.parseFloat(hourMatch[1]);
    if (Number.isFinite(hours) && hours > 0) return clamp(Math.round(hours * 60), 15, 8 * 60);
  }
  const minMatch = raw.match(/(\d+)\s*(分|m|min|mins|minute|minutes)/i);
  if (minMatch) {
    const mins = Number.parseInt(minMatch[1], 10);
    if (Number.isFinite(mins) && mins > 0) return clamp(mins, 15, 8 * 60);
  }

  const quickWords = ['確認', '返信', '連絡', 'メール', 'チェック', '買う', '購入'];
  const longWords = ['設計', '実装', '資料', 'まとめ', '作成', 'レポート', '提出', '調査', 'レビュー'];
  const lower = raw.toLowerCase();
  if (quickWords.some((w) => lower.includes(w.toLowerCase()))) return 30;
  if (longWords.some((w) => lower.includes(w.toLowerCase()))) return 90;
  return 60;
}

function loadProfile(profilePath) {
  try {
    if (!profilePath || !fs.existsSync(profilePath)) {
      return {
        version: 1,
        stats: {
          runs: 0,
          avgEstimatedMinutes: 60,
          avgGapMinutes: 30,
        },
      };
    }
    const parsed = JSON.parse(fs.readFileSync(profilePath, 'utf8'));
    if (!parsed || typeof parsed !== 'object') throw new Error('invalid profile');
    if (!parsed.stats || typeof parsed.stats !== 'object') parsed.stats = {};
    if (!Number.isFinite(parsed.stats.runs)) parsed.stats.runs = 0;
    if (!Number.isFinite(parsed.stats.avgEstimatedMinutes)) parsed.stats.avgEstimatedMinutes = 60;
    if (!Number.isFinite(parsed.stats.avgGapMinutes)) parsed.stats.avgGapMinutes = 30;
    return parsed;
  } catch {
    return {
      version: 1,
      stats: {
        runs: 0,
        avgEstimatedMinutes: 60,
        avgGapMinutes: 30,
      },
    };
  }
}

function saveProfile(profilePath, profile) {
  if (!profilePath) return;
  const dir = path.dirname(profilePath);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(profilePath, JSON.stringify(profile, null, 2));
}

function deriveGapMinutes(profile, estimatedMinutes, fixedSpacing) {
  if (fixedSpacing > 0) return clamp(fixedSpacing, 10, 240);
  const learnedGap = Number(profile?.stats?.avgGapMinutes ?? 30);
  const suggestedGap = clamp(Math.round(estimatedMinutes * 0.5), 15, 180);
  return clamp(Math.round(learnedGap * 0.7 + suggestedGap * 0.3), 15, 180);
}

function pickDueDateTime(holidayDate, dueTime, reminders, gapMinutes) {
  const base = parseHmToMinutes(dueTime);
  const dayMinutes = reminders
    .map((item) => extractDueLocalDateAndMinute(item?.dueDate))
    .filter(Boolean)
    .filter((item) => item.ymd === holidayDate)
    .map((item) => item.minute)
    .sort((a, b) => a - b);

  let candidate = base;
  while (candidate <= 23 * 60 + 45) {
    const conflicted = dayMinutes.some((minute) => Math.abs(minute - candidate) < gapMinutes);
    if (!conflicted) {
      return `${holidayDate} ${minutesToHm(candidate)}`;
    }
    candidate += gapMinutes;
  }
  return `${holidayDate} 23:45`;
}

function dueDateFromValue(value) {
  return extractDateKey(value);
}

function taskSignature(title, dueDate) {
  const normalizedTitle = String(title ?? '').trim().toLowerCase();
  const normalizedDue = dueDateFromValue(dueDate);
  return `${normalizedTitle}__${normalizedDue}`;
}

function ensureRemindersAuthorized() {
  const status = runRemindctlJson(['status']);
  if (status?.authorized === false) {
    throw new Error('Apple Reminders の権限がありません。先に `remindctl authorize` を実行してください。');
  }
}

function ensureListExists(listName) {
  if (!listName) return;
  const lists = asArray(runRemindctlJson(['list']));
  const wanted = String(listName).toLowerCase();
  const matched = lists.find(
    (item) =>
      String(item.id ?? '').toLowerCase() === wanted ||
      String(item.title ?? '').toLowerCase() === wanted,
  );
  if (!matched) {
    const available = lists.map((item) => item.title ?? '(no title)').join(', ');
    throw new Error(`リストが見つかりません (${listName})。利用可能: ${available}`);
  }
}

function loadTargetReminders(listName) {
  return listName
    ? asArray(runRemindctlJson(['list', listName]))
    : asArray(runRemindctlJson(['all']));
}

function hasDuplicateReminder(reminders, title, dueDate) {
  const signature = taskSignature(title, dueDate);
  return reminders.some((item) => taskSignature(item.title, item.dueDate) === signature);
}

function formatAddArgs({ title, dueDate, listName, notes }) {
  const args = ['add', '--title', title, '--due', dueDate];
  if (listName) args.push('--list', listName);
  if (notes) args.push('--notes', notes);
  return args;
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const title = extractTaskTitle(opts.input, opts.title);

  const events = runGogJson(
    [
      'calendar',
      'events',
      opts.calendarId,
      '--from',
      opts.from,
      '--to',
      opts.to,
      '--max',
      '250',
      '--all-pages',
    ],
    opts.account,
  );

  const holidayDate = pickNextHolidayDate(events, {
    from: opts.from,
    to: opts.to,
    eventTypes: opts.eventTypes,
    summaryKeywords: opts.summaryKeywords,
    workKeywords: opts.workKeywords,
    allDayOnly: opts.allDayOnly,
  });

  if (!holidayDate) {
    throw new Error(`期間 ${opts.from}..${opts.to} に休み日が見つかりません。`);
  }

  ensureRemindersAuthorized();
  ensureListExists(opts.list);
  const reminders = loadTargetReminders(opts.list);
  const profile = loadProfile(opts.profilePath);
  const estimatedMinutes = estimateTaskMinutes(`${title} ${opts.input ?? ''}`);
  const gapMinutes = deriveGapMinutes(profile, estimatedMinutes, opts.fixedSpacing);
  const dueDateTime = pickDueDateTime(holidayDate, opts.dueTime, reminders, gapMinutes);

  console.log(`タイトル: ${title}`);
  console.log(`休み日: ${holidayDate}`);
  console.log(`追加時刻: ${dueDateTime}`);
  console.log(`想定所要時間(分): ${estimatedMinutes}`);
  console.log(`間隔設定(分): ${gapMinutes}`);
  if (opts.list) {
    console.log(`リスト: ${opts.list}`);
  }

  const duplicated = hasDuplicateReminder(reminders, title, holidayDate);
  if (duplicated) {
    console.log('重複判定: 既存ありのため追加スキップ');
    return;
  }

  const notes = [
    '自動追加: 「あとで」入力',
    opts.input ? `入力: ${opts.input}` : '',
    `休み日: ${holidayDate}`,
    `追加時刻: ${dueDateTime}`,
    `想定所要時間: ${estimatedMinutes}分`,
    `調整間隔: ${gapMinutes}分`,
  ]
    .filter(Boolean)
    .join('\n');

  const addArgs = formatAddArgs({
    title,
    dueDate: dueDateTime,
    listName: opts.list,
    notes,
  });

  console.log(`重複判定: 追加対象`);
  console.log(`実行コマンド: remindctl ${addArgs.join(' ')}`);

  if (!opts.apply) {
    console.log('dry-run: 追加は実行していません。--apply を付けると反映します。');
    return;
  }

  runRemindctlText(addArgs, { retryMach4099: true });
  const runs = Number(profile?.stats?.runs ?? 0) + 1;
  const prevAvgEstimate = Number(profile?.stats?.avgEstimatedMinutes ?? estimatedMinutes);
  const prevAvgGap = Number(profile?.stats?.avgGapMinutes ?? gapMinutes);
  profile.version = 1;
  profile.stats = {
    runs,
    avgEstimatedMinutes: clamp(Math.round(prevAvgEstimate * 0.8 + estimatedMinutes * 0.2), 15, 8 * 60),
    avgGapMinutes: clamp(Math.round(prevAvgGap * 0.8 + gapMinutes * 0.2), 10, 240),
    lastUsedAt: new Date().toISOString(),
    lastDueDateTime: dueDateTime,
  };
  saveProfile(opts.profilePath, profile);
  console.log('結果: 追加成功');
}

try {
  main();
} catch (error) {
  process.stderr.write(`エラー: ${error.message}\n`);
  process.exit(1);
}
