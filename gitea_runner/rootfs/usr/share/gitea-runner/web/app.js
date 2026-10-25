'use strict';

// Texts of the app page, English and German. The page follows the browser language.
const TEXT = {
  en: {
    recheck: 'Check again',
    rechecking: 'Checking…',
    copy: 'Copy',
    copied: 'Copied',
    starting: 'The app is starting. This page updates in a moment…',
    checkedAt: 'Last checked {0}',
    preRelease: 'Pre-release {0}',
    problems: 'Needs attention',
    openConfig: 'Open app configuration',

    tab_overview: 'Overview',
    tab_setup: 'Set up',
    tab_workflows: 'Workflows',
    tab_limits: 'Safety and limits',

    overviewIntro: 'Gitea Actions runs workflows (build, test, deploy) when you push to a repository. Gitea only schedules them; a runner executes them. This app is such a runner. It runs the jobs inside the app, isolated from the rest of Home Assistant.',
    status: 'Status',
    giteaOk: 'Gitea {0} is reachable',
    giteaOkNoVersion: 'Gitea is reachable',
    giteaDefault: '{0} (the Gitea app by alexbelgium, the default)',
    giteaUrl: '{0} (address from the app configuration)',
    giteaBad: 'Gitea does not answer',
    regRegistered: 'The runner “{0}” is registered',
    regRegisteredDetail: 'Gitea shows it under Actions → Runners. Once registered you can remove the token from the configuration.',
    regStarting: 'Registration is being prepared…',
    regWaiting: 'Waiting for Gitea to answer',
    regNeeds: 'A registration token is needed',
    regNeedsDetail: 'Copy it from Gitea (see the tab “Set up”) and enter it as “Registration token” in the app configuration. Restart the app afterwards.',
    regRejected: 'Gitea refused the registration',
    regFailed: 'The runner could not be registered',
    runnerUp: 'The runner is connected and waits for jobs',
    runnerUpDetail: 'It takes up to {0} job(s) at a time.',
    runnerBusy: '{0} of {1} jobs are running',
    runnerNotReady: 'The runner is starting or cannot reach Gitea',
    runnerDown: 'The runner is not running',
    labelsTitle: 'Labels',
    labelsDetail: 'Put one of these in “runs-on” of a workflow to run it here: {0}.',
    jobsDone: 'Jobs since the app started',
    jobsDoneDetail: '{0} succeeded, {1} failed or cancelled.',
    isolationTitle: 'Isolated by design',
    isolationText: 'The app has no access to Docker, to the Supervisor or to your Home Assistant files, and it does not run with extra privileges. Jobs run as root inside the app, with a low priority, and are stopped first when memory runs short. Read “Safety and limits” before you register the runner for repositories you do not control.',

    setupTitle: 'Register the runner',
    setupIntro: 'Needed once. The registration is kept, also in backups.',
    setupStep1: 'Switch on Actions',
    setupStep1Text: 'Current Gitea versions have Actions on. Open a repository, go to Settings → Repository and enable “Actions”. If the section is missing, Actions are switched off for the whole Gitea (setting ENABLED in the [actions] section of app.ini).',
    setupStep2: 'Copy a registration token',
    setupStep2Text: 'In Gitea open the runners page and create a new runner, then copy the token. Where you open it decides who may use the runner: Site administration → Actions → Runners for every repository, an organization’s Settings → Actions → Runners for its repositories, a repository’s Settings → Actions → Runners for that repository only.',
    setupStep3: 'Enter it here',
    setupStep3Text: 'Paste the token as “Registration token” in the app configuration and restart the app. If your Gitea is not the Gitea app by alexbelgium, change “Gitea address” as well.',
    setupStep4: 'Check',
    setupStep4Text: 'This page shows the runner as registered and connected, and Gitea lists it as online after a short while. Then remove the token from the configuration: it is not needed any more. To register again (another Gitea, another scope), enter a new token and restart.',
    addresses: 'Gitea address in use',
    openConfig2: 'Open app configuration',

    workflowsTitle: 'Workflows',
    workflowsIntro: 'Workflows are YAML files in the folder .gitea/workflows of a repository. “runs-on” picks the runner by label. These examples use the label {0}.',
    wfHello: '.gitea/workflows/hello.yaml, the smallest useful workflow',
    wfTools: '.gitea/workflows/tools.yaml, installs what a job needs (the image is Alpine Linux and jobs run as root)',
    wfReload: '.gitea/workflows/reload.yaml, checks and reloads Home Assistant through its API',
    wfReloadHint: 'Create a long-lived access token in your Home Assistant profile (Security) and save it in Gitea as the secret HA_TOKEN (repository Settings → Actions → Secrets). Only workflows of that repository can use it. “homeassistant” is the address of Home Assistant inside its internal network.',
    wfDeploy: '.gitea/workflows/deploy.yaml, copies files to another machine over SSH',
    wfDeployHint: 'Create a key pair, put the public key on the target and save the private key as the secret DEPLOY_KEY. The host and path are examples.',

    limitsTitle: 'Safety and limits',
    limitsWhy: 'Why no Docker?',
    limitsWhyText: 'Jobs in containers need access to the Docker engine of Home Assistant OS, and whoever may use that engine controls the whole host. A workflow that compiles firmware with several parallel compilers then takes down Home Assistant itself, which has happened. This app therefore runs jobs inside its own container, where memory shortage and runaway jobs hit the app and not the host. The price is that there are no container jobs and no “docker build”.',
    limitsHas: 'What the app has',
    limitsHas1: 'A low CPU priority, only the CPU cores you allow (one by default, option “CPU cores for jobs”) and the highest OOM score: Home Assistant keeps a core, and when memory runs out, the kernel stops a job before Home Assistant.',
    limitsHas2: 'No Supervisor or Home Assistant API, no folders, no Docker, no privileges. Jobs reach your network like every app does, so other apps and Home Assistant can be called by their names.',
    limitsHas3: 'One job at a time by default. Raise “Parallel jobs” only if the device has memory to spare.',
    limitsLimits: 'What it cannot do',
    limitsLimit1: 'Alpine Linux uses musl instead of glibc. Programs that only exist for glibc, such as the toolchains of PlatformIO and ESPHome or the downloads of setup-node and setup-python, do not run. Install what you need with “apk add” (see the Workflows tab), or run such builds elsewhere.',
    limitsLimit2: 'No “docker build”, no service containers, no “container:” in a workflow.',
    limitsLimit3: 'Heavy builds belong on a separate machine. You can run the official runner there and register it with the same Gitea; this app then stays for light jobs next to Home Assistant.',
    limitsTrust: 'Who may use it',
    limitsTrustText: 'Jobs run arbitrary commands as root inside the app. Register the runner only for repositories and organizations you trust (see “Set up”, step 2), and be careful with workflows in pull requests from strangers.',

    reason_host_unknown: 'the host name is unknown',
    reason_refused: 'the connection was refused (is the app started?)',
    reason_timeout: 'the request timed out',
    reason_tls: 'the TLS certificate is not trusted (see the advanced options)',
    reason_failed: 'the connection failed (curl error {rc})',
    m_no_answer: 'Gitea does not answer: {reason}.',
    m_not_gitea: '{url} answers, but it does not look like Gitea (HTTP {http}). Check the address.',
    m_registered: 'The runner is registered.',
    m_waiting: 'Gitea does not answer yet. The app tries again by itself.',
    m_needs_credentials: 'Enter a registration token in the app configuration.',
    m_registration_token_rejected: 'Gitea does not accept this registration token. Copy a fresh one from the runners page of Gitea.',
    m_register_failed: 'The runner could not be registered: {detail}',
    m_bad_gitea_url: 'The Gitea address “{url}” is not a web address. Use the form http://db21ed7f-gitea:3000.',
    m_bad_runner_name: 'The runner name “{name}” may only hold letters, digits, blanks, dots, dashes and underscores.',
    m_bad_label: 'The label “{label}” is not valid. Use letters, digits, dots, dashes and underscores.',
    m_no_labels: 'There is no label, so no workflow could use this runner. Add at least one, for example home-assistant.',
  },
  de: {
    recheck: 'Erneut prüfen',
    rechecking: 'Prüfe…',
    copy: 'Kopieren',
    copied: 'Kopiert',
    starting: 'Die App startet. Diese Seite aktualisiert sich gleich…',
    checkedAt: 'Zuletzt geprüft {0}',
    preRelease: 'Vorabversion {0}',
    problems: 'Das braucht Aufmerksamkeit',
    openConfig: 'App-Konfiguration öffnen',

    tab_overview: 'Übersicht',
    tab_setup: 'Einrichten',
    tab_workflows: 'Workflows',
    tab_limits: 'Sicherheit und Grenzen',

    overviewIntro: 'Gitea Actions führt Workflows (bauen, testen, ausliefern) aus, wenn du in ein Repository pushst. Gitea plant sie nur; ein Runner führt sie aus. Diese App ist so ein Runner. Sie führt die Jobs innerhalb der App aus, abgeschottet vom Rest von Home Assistant.',
    status: 'Status',
    giteaOk: 'Gitea {0} ist erreichbar',
    giteaOkNoVersion: 'Gitea ist erreichbar',
    giteaDefault: '{0} (die Gitea-App von alexbelgium, der Standard)',
    giteaUrl: '{0} (Adresse aus der App-Konfiguration)',
    giteaBad: 'Gitea antwortet nicht',
    regRegistered: 'Der Runner „{0}“ ist registriert',
    regRegisteredDetail: 'Gitea zeigt ihn unter Actions → Runner. Nach der Registrierung kannst du den Token aus der Konfiguration entfernen.',
    regStarting: 'Die Registrierung wird vorbereitet…',
    regWaiting: 'Warte darauf, dass Gitea antwortet',
    regNeeds: 'Ein Registrierungstoken wird gebraucht',
    regNeedsDetail: 'Kopiere ihn aus Gitea (siehe Reiter „Einrichten“) und trage ihn in der App-Konfiguration als „Registrierungstoken“ ein. Starte die App danach neu.',
    regRejected: 'Gitea hat die Registrierung abgelehnt',
    regFailed: 'Der Runner konnte nicht registriert werden',
    runnerUp: 'Der Runner ist verbunden und wartet auf Jobs',
    runnerUpDetail: 'Er übernimmt bis zu {0} Job(s) gleichzeitig.',
    runnerBusy: '{0} von {1} Jobs laufen',
    runnerNotReady: 'Der Runner startet oder erreicht Gitea nicht',
    runnerDown: 'Der Runner läuft nicht',
    labelsTitle: 'Labels',
    labelsDetail: 'Trage eines davon bei „runs-on“ eines Workflows ein, damit er hier läuft: {0}.',
    jobsDone: 'Jobs seit dem Start der App',
    jobsDoneDetail: '{0} erfolgreich, {1} fehlgeschlagen oder abgebrochen.',
    isolationTitle: 'Bewusst abgeschottet',
    isolationText: 'Die App hat keinen Zugriff auf Docker, auf den Supervisor oder auf deine Home-Assistant-Dateien und läuft ohne zusätzliche Rechte. Jobs laufen als root innerhalb der App, mit niedriger Priorität, und werden zuerst beendet, wenn der Speicher knapp wird. Lies „Sicherheit und Grenzen“, bevor du den Runner für Repositories registrierst, die du nicht kontrollierst.',

    setupTitle: 'Runner registrieren',
    setupIntro: 'Wird einmal gebraucht. Die Registrierung bleibt erhalten, auch in Backups.',
    setupStep1: 'Actions einschalten',
    setupStep1Text: 'Aktuelle Gitea-Versionen haben Actions eingeschaltet. Öffne ein Repository, gehe zu Einstellungen → Repository und aktiviere „Actions“. Fehlt der Abschnitt, sind Actions für das ganze Gitea abgeschaltet (Einstellung ENABLED im Abschnitt [actions] der app.ini).',
    setupStep2: 'Registrierungstoken kopieren',
    setupStep2Text: 'Öffne in Gitea die Runner-Seite und lege einen neuen Runner an, dann kopiere den Token. Wo du sie öffnest, bestimmt, wer den Runner nutzen darf: Website-Administration → Actions → Runner für alle Repositories, Einstellungen → Actions → Runner einer Organisation für deren Repositories, Einstellungen → Actions → Runner eines Repositorys nur für dieses.',
    setupStep3: 'Hier eintragen',
    setupStep3Text: 'Füge den Token als „Registrierungstoken“ in der App-Konfiguration ein und starte die App neu. Ist dein Gitea nicht die Gitea-App von alexbelgium, ändere auch die „Gitea-Adresse“.',
    setupStep4: 'Prüfen',
    setupStep4Text: 'Diese Seite zeigt den Runner als registriert und verbunden, und Gitea führt ihn nach kurzer Zeit als online. Entferne danach den Token aus der Konfiguration: Er wird nicht mehr gebraucht. Für eine neue Registrierung (anderes Gitea, anderer Bereich) trage einen neuen Token ein und starte neu.',
    addresses: 'Verwendete Gitea-Adresse',
    openConfig2: 'App-Konfiguration öffnen',

    workflowsTitle: 'Workflows',
    workflowsIntro: 'Workflows sind YAML-Dateien im Ordner .gitea/workflows eines Repositorys. „runs-on“ wählt den Runner über das Label. Diese Beispiele nutzen das Label {0}.',
    wfHello: '.gitea/workflows/hello.yaml, der kleinste nützliche Workflow',
    wfTools: '.gitea/workflows/tools.yaml, installiert, was ein Job braucht (das Image ist Alpine Linux und Jobs laufen als root)',
    wfReload: '.gitea/workflows/reload.yaml, prüft das laufende Home Assistant und lädt es über die API neu',
    wfReloadHint: 'Erstelle in deinem Home-Assistant-Profil (Sicherheit) einen langlebigen Zugriffstoken und speichere ihn in Gitea als Secret HA_TOKEN (Repository Einstellungen → Actions → Secrets). Nur Workflows dieses Repositorys können ihn nutzen. „homeassistant“ ist die Adresse von Home Assistant im internen Netzwerk.',
    wfDeploy: '.gitea/workflows/deploy.yaml, kopiert Dateien per SSH auf einen anderen Rechner',
    wfDeployHint: 'Erzeuge ein Schlüsselpaar, lege den öffentlichen Schlüssel auf dem Ziel ab und speichere den privaten als Secret DEPLOY_KEY. Host und Pfad sind Beispiele.',

    limitsTitle: 'Sicherheit und Grenzen',
    limitsWhy: 'Warum kein Docker?',
    limitsWhyText: 'Jobs in Containern brauchen Zugriff auf die Docker-Engine von Home Assistant OS, und wer diese Engine nutzen darf, kontrolliert den ganzen Host. Ein Workflow, der Firmware mit mehreren parallelen Compilern baut, reißt dann Home Assistant selbst mit, das ist schon passiert. Diese App führt Jobs deshalb in ihrem eigenen Container aus: Speichermangel und außer Kontrolle geratene Jobs treffen die App und nicht den Host. Der Preis: keine Container-Jobs und kein „docker build“.',
    limitsHas: 'Was die App hat',
    limitsHas1: 'Eine niedrige CPU-Priorität, nur die CPU-Kerne, die du erlaubst (standardmäßig einen, Option „CPU-Kerne für Jobs“) und den höchsten OOM-Wert: Home Assistant behält einen Kern, und wird der Speicher knapp, beendet der Kernel einen Job vor Home Assistant.',
    limitsHas2: 'Keinen Supervisor- oder Home-Assistant-API-Zugriff, keine Ordner, kein Docker, keine Rechte. Jobs erreichen dein Netzwerk wie jede App, andere Apps und Home Assistant lassen sich also über ihre Namen aufrufen.',
    limitsHas3: 'Standardmäßig einen Job gleichzeitig. Erhöhe „Parallele Jobs“ nur, wenn das Gerät Speicher übrig hat.',
    limitsLimits: 'Was sie nicht kann',
    limitsLimit1: 'Alpine Linux nutzt musl statt glibc. Programme, die es nur für glibc gibt, etwa die Toolchains von PlatformIO und ESPHome oder die Downloads von setup-node und setup-python, laufen nicht. Installiere, was du brauchst, mit „apk add“ (siehe Reiter Workflows), oder führe solche Builds woanders aus.',
    limitsLimit2: 'Kein „docker build“, keine Service-Container, kein „container:“ in einem Workflow.',
    limitsLimit3: 'Schwere Builds gehören auf einen eigenen Rechner. Dort kannst du den offiziellen Runner betreiben und am selben Gitea registrieren; diese App bleibt dann für leichte Jobs neben Home Assistant.',
    limitsTrust: 'Wer sie nutzen darf',
    limitsTrustText: 'Jobs führen beliebige Befehle als root innerhalb der App aus. Registriere den Runner nur für Repositories und Organisationen, denen du vertraust (siehe „Einrichten“, Schritt 2), und sei vorsichtig mit Workflows in Pull Requests von Fremden.',

    reason_host_unknown: 'der Hostname ist unbekannt',
    reason_refused: 'die Verbindung wurde abgelehnt (läuft die App?)',
    reason_timeout: 'die Anfrage hat das Zeitlimit überschritten',
    reason_tls: 'dem TLS-Zertifikat wird nicht vertraut (siehe Erweitert)',
    reason_failed: 'die Verbindung ist fehlgeschlagen (curl-Fehler {rc})',
    m_no_answer: 'Gitea antwortet nicht: {reason}.',
    m_not_gitea: '{url} antwortet, sieht aber nicht nach Gitea aus (HTTP {http}). Prüfe die Adresse.',
    m_registered: 'Der Runner ist registriert.',
    m_waiting: 'Gitea antwortet noch nicht. Die App versucht es von selbst wieder.',
    m_needs_credentials: 'Trage in der App-Konfiguration einen Registrierungstoken ein.',
    m_registration_token_rejected: 'Gitea akzeptiert diesen Registrierungstoken nicht. Kopiere einen frischen von der Runner-Seite in Gitea.',
    m_register_failed: 'Der Runner konnte nicht registriert werden: {detail}',
    m_bad_gitea_url: 'Die Gitea-Adresse „{url}“ ist keine Webadresse. Nutze die Form http://db21ed7f-gitea:3000.',
    m_bad_runner_name: 'Der Runner-Name „{name}“ darf nur Buchstaben, Ziffern, Leerzeichen, Punkte, Bindestriche und Unterstriche enthalten.',
    m_bad_label: 'Das Label „{label}“ ist ungültig. Nutze Buchstaben, Ziffern, Punkte, Bindestriche und Unterstriche.',
    m_no_labels: 'Es gibt kein Label, daher könnte kein Workflow diesen Runner nutzen. Füge mindestens eines hinzu, zum Beispiel home-assistant.',
  },
};

// German only when the browser prefers German; everything else is English.
const preferred = (navigator.languages && navigator.languages[0]) || navigator.language || 'en';
const language = preferred.toLowerCase().startsWith('de') ? 'de' : 'en';
document.documentElement.lang = language;

function t(key, ...values) {
  return values.reduce((text, value, index) => text.replace(`{${index}}`, value), TEXT[language][key]);
}

// fill(template, values): replaces {name} with values.name.
function fill(template, values = {}) {
  return template.replace(/\{(\w+)\}/g, (match, name) => (name in values ? values[name] : match));
}

// explain(entry, fallback): the message of a check or problem in the language of the page.
// The backend sends a code with arguments next to its English text; unknown codes show the text.
function explain(entry, fallback = '') {
  const template = entry && entry.code && TEXT[language][`m_${entry.code}`];
  if (!template) return fallback || (entry && (entry.error || entry.text)) || '';
  const args = { ...entry.args };
  if (args.reason) args.reason = fill(TEXT[language][`reason_${args.reason}`] || args.reason, args);
  return fill(template, args);
}

// el(tag, properties, ...children): a small helper that builds DOM nodes without parsing HTML,
// so values from the status file can never be interpreted as markup.
function el(tag, properties = {}, ...children) {
  const node = document.createElement(tag);
  Object.assign(node, properties);
  node.append(...children.flat().filter((child) => child !== null && child !== undefined && child !== false));
  return node;
}

function row(state, title, detail) {
  const icon = { ok: '✓', warn: '!', bad: '✗' }[state];
  return el('div', { className: `row ${state}` },
    el('span', { className: 'icon' }, icon),
    el('div', {}, el('div', { className: 'title' }, title), detail && el('div', { className: 'detail' }, detail)));
}

function copyButton(source) {
  const button = el('button', { type: 'button' }, t('copy'));
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(source.value);
    } catch {
      // Ingress frames may not use the clipboard API; selecting and copying still works.
      source.select();
      document.execCommand('copy');
    }
    button.textContent = t('copied');
    setTimeout(() => { button.textContent = t('copy'); }, 1500);
  });
  return button;
}

function field(label, value, rows = 0) {
  const input = rows
    ? el('textarea', { readOnly: true, rows, value })
    : el('input', { readOnly: true, value });
  return el('div', { className: 'field' }, el('label', {}, label), el('div', { className: 'line' }, input, copyButton(input)));
}

function link(href, text, primary) {
  return el('a', { href, target: '_blank', rel: 'noopener', className: primary ? 'button primary' : 'button' }, text);
}

function card(title, ...children) {
  return el('section', { className: 'card' }, title && el('h2', {}, title), ...children);
}

function callout(kind, ...children) {
  return el('div', { className: `callout ${kind}` }, ...children);
}

// steps([title, ...content], ...): numbered instructions.
function steps(...items) {
  return el('ol', { className: 'steps' }, items.map(([title, ...content]) => el('li', {}, el('h3', {}, title), ...content)));
}

function configLink(status) {
  const slug = status.app.hostname.replace(/-/g, '_');
  return link(`https://my.home-assistant.io/redirect/supervisor_addon/?addon=${slug}`, t('openConfig'));
}

// ---- workflows ---------------------------------------------------------------------------------

function workflowHello(label) {
  return [
    'name: Hello',
    'on: [push, workflow_dispatch]',
    'jobs:',
    '  hello:',
    `    runs-on: ${label}`,
    '    steps:',
    '      - uses: actions/checkout@v4',
    '      - run: echo "Hello from Home Assistant"',
  ].join('\n');
}

function workflowTools(label) {
  return [
    'name: Tools',
    'on: [push]',
    'jobs:',
    '  yamllint:',
    `    runs-on: ${label}`,
    '    steps:',
    '      - uses: actions/checkout@v4',
    '      - run: |',
    '          apk add --no-cache yamllint',
    '          yamllint -d relaxed .',
  ].join('\n');
}

function workflowReload(label) {
  return [
    'name: Reload Home Assistant',
    'on: [push]',
    'jobs:',
    '  reload:',
    `    runs-on: ${label}`,
    '    steps:',
    '      - name: Check the configuration',
    '        run: |',
    '          curl -fsS -X POST -H "Authorization: Bearer ${{ secrets.HA_TOKEN }}" \\',
    '            http://homeassistant:8123/api/config/core/check_config | tee check.json',
    '          grep -q \'"result": *"valid"\' check.json',
    '      - name: Reload everything that can be reloaded',
    '        run: |',
    '          curl -fsS -X POST -H "Authorization: Bearer ${{ secrets.HA_TOKEN }}" \\',
    '            http://homeassistant:8123/api/services/homeassistant/reload_all',
  ].join('\n');
}

function workflowDeploy(label) {
  return [
    'name: Deploy',
    'on:',
    '  push:',
    '    branches: [main]',
    'jobs:',
    '  deploy:',
    `    runs-on: ${label}`,
    '    steps:',
    '      - uses: actions/checkout@v4',
    '      - name: Copy the files',
    '        run: |',
    '          mkdir -p ~/.ssh',
    '          echo "${{ secrets.DEPLOY_KEY }}" > ~/.ssh/id_ed25519',
    '          chmod 600 ~/.ssh/id_ed25519',
    '          ssh-keyscan -H target.example >> ~/.ssh/known_hosts',
    '          tar -c lovelace | ssh deploy@target.example "tar -x -C /srv/lovelace"',
  ].join('\n');
}

// ---- panels ----------------------------------------------------------------------------------

function giteaRow(status) {
  const gitea = status.gitea;
  const source = gitea.source === 'default' ? 'giteaDefault' : 'giteaUrl';
  if (!gitea.url) return row('bad', t('giteaBad'));
  return gitea.reachable
    ? row('ok', gitea.version ? t('giteaOk', gitea.version) : t('giteaOkNoVersion'), t(source, gitea.url))
    : row('bad', t('giteaBad'), `${gitea.url}: ${explain(gitea)}`);
}

function registrationRow(status) {
  const registration = status.registration;
  const detail = explain(registration);
  switch (registration.state) {
    case 'registered': return row('ok', t('regRegistered', registration.name), t('regRegisteredDetail'));
    case 'waiting': return row('warn', t('regWaiting'), detail);
    case 'needs_credentials': return row('bad', t('regNeeds'), t('regNeedsDetail'));
    case 'rejected': return row('bad', t('regRejected'), detail);
    case 'failed': return row('bad', t('regFailed'), detail);
    default: return row('warn', t('regStarting'));
  }
}

function runnerRows(status) {
  const runner = status.runner;
  const rows = [];
  if (status.registration.state !== 'registered') return rows;

  if (!runner.running) rows.push(row('bad', t('runnerDown')));
  else if (!runner.ready) rows.push(row('warn', t('runnerNotReady')));
  else if (runner.jobs_running > 0) rows.push(row('ok', t('runnerBusy', runner.jobs_running, runner.capacity)));
  else rows.push(row('ok', t('runnerUp'), t('runnerUpDetail', runner.capacity)));

  if (runner.jobs_succeeded + runner.jobs_failed > 0) {
    rows.push(row('ok', t('jobsDone'), t('jobsDoneDetail', runner.jobs_succeeded, runner.jobs_failed)));
  }
  return rows;
}

function overviewPanel(status) {
  return [
    card(null, el('p', {}, t('overviewIntro'))),
    card(t('status'), giteaRow(status), registrationRow(status), ...runnerRows(status),
      status.runner.labels.length > 0 && row('ok', t('labelsTitle'), t('labelsDetail', status.runner.labels.join(', '))),
      el('div', { className: 'actions' }, configLink(status))),
    card(t('isolationTitle'), el('p', {}, t('isolationText'))),
  ];
}

function setupPanel(status) {
  return [card(t('setupTitle'), el('p', {}, t('setupIntro')),
    steps(
      [t('setupStep1'), el('p', {}, t('setupStep1Text'))],
      [t('setupStep2'), el('p', {}, t('setupStep2Text'))],
      [t('setupStep3'), el('p', {}, t('setupStep3Text')), field(t('addresses'), status.gitea.url),
        el('div', { className: 'actions' }, configLink(status))],
      [t('setupStep4'), el('p', {}, t('setupStep4Text'))]))];
}

function workflowsPanel(status) {
  const label = status.runner.labels[0] || 'home-assistant';
  return [card(t('workflowsTitle'), el('p', {}, t('workflowsIntro', label)),
    field(t('wfHello'), workflowHello(label), 9),
    field(t('wfTools'), workflowTools(label), 11),
    field(t('wfReload'), workflowReload(label), 15),
    el('p', { className: 'muted' }, t('wfReloadHint')),
    field(t('wfDeploy'), workflowDeploy(label), 16),
    el('p', { className: 'muted' }, t('wfDeployHint')))];
}

function limitsPanel() {
  const list = (keys) => el('ul', {}, keys.map((key) => el('li', {}, t(key))));
  return [
    card(t('limitsTitle'), el('h3', {}, t('limitsWhy')), el('p', {}, t('limitsWhyText'))),
    card(t('limitsHas'), list(['limitsHas1', 'limitsHas2', 'limitsHas3'])),
    card(t('limitsLimits'), list(['limitsLimit1', 'limitsLimit2', 'limitsLimit3'])),
    card(t('limitsTrust'), callout('warn', el('p', {}, t('limitsTrustText')))),
  ];
}

const TABS = [['overview', overviewPanel], ['setup', setupPanel], ['workflows', workflowsPanel], ['limits', limitsPanel]];

// ---- tabs and rendering ----------------------------------------------------------------------

let currentTab = TABS.some(([name]) => name === location.hash.slice(1)) ? location.hash.slice(1) : 'overview';

function showTab(name) {
  currentTab = name;
  history.replaceState(null, '', `#${name}`);
  for (const [tab] of TABS) {
    document.getElementById(`panel-${tab}`).hidden = tab !== name;
    document.getElementById(`tab-${tab}`).setAttribute('aria-selected', String(tab === name));
  }
}

function buildTabs() {
  const nav = document.getElementById('tabs');
  const panels = document.getElementById('panels');
  for (const [name] of TABS) {
    const button = el('button', { type: 'button', id: `tab-${name}`, role: 'tab' }, t(`tab_${name}`));
    button.addEventListener('click', () => { showTab(name); window.scrollTo({ top: 0 }); });
    nav.append(button);
    panels.append(el('div', { id: `panel-${name}`, className: 'panel', role: 'tabpanel' }));
  }
}

function renderProblems(status) {
  const banner = document.getElementById('problems');
  banner.hidden = status.problems.length === 0;
  const details = status.problem_details && status.problem_details.length ? status.problem_details : null;
  const lines = details ? details.map((problem) => explain(problem)) : status.problems;
  banner.replaceChildren(el('h2', {}, t('problems')), ...lines.map((line) => el('p', {}, line)));
}

// What the panels show, without the time of the check: they are only drawn again when it changes,
// so that text the user is selecting or has copied stays untouched by the regular refresh.
let lastContent = '';

function render(status) {
  const release = document.getElementById('release');
  const prerelease = status.app.version.includes('-') ? status.app.version.split('-').slice(1).join('-') : '';
  release.hidden = !prerelease;
  release.textContent = t('preRelease', prerelease);
  document.getElementById('checked').textContent = t('checkedAt', new Date(status.checked_at).toLocaleString());
  renderProblems(status);

  const content = JSON.stringify({ ...status, checked_at: '' });
  if (content === lastContent) return;
  lastContent = content;
  for (const [name, build] of TABS) {
    document.getElementById(`panel-${name}`).replaceChildren(...build(status).filter(Boolean));
  }
  showTab(currentTab);
}

async function load(attempt = 0) {
  const reply = await fetch('status.json', { cache: 'no-store' });
  if (reply.ok) return render(await reply.json());
  // The start script writes the status a moment after the page server is up.
  document.getElementById('checked').textContent = t('starting');
  if (attempt < 30) setTimeout(() => load(attempt + 1), 2000);
}

async function refresh(button) {
  if (button) {
    button.disabled = true;
    button.textContent = t('rechecking');
  }
  try {
    const reply = await fetch('cgi-bin/recheck', { method: 'POST' });
    if (reply.ok) render(await reply.json());
  } catch {
    // The next round tries again.
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = t('recheck');
    }
  }
}

const recheckButton = document.getElementById('recheck');
recheckButton.textContent = t('recheck');
recheckButton.addEventListener('click', () => refresh(recheckButton));
document.title = 'Gitea Runner';
buildTabs();
load();
// While the page is open, the status refreshes itself: jobs start and end, the runner goes online.
setInterval(() => { if (document.visibilityState === 'visible') refresh(null); }, 15000);
