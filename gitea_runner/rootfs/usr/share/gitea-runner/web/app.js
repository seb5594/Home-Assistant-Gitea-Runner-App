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
    notices: 'Good to know',
    runner: 'Runner',
    noGitea: 'No Gitea configured',
    noGiteaDetail: 'Install the Gitea app, or enter the address of your Gitea in the app configuration.',
    giteaOk: 'Gitea {0} is reachable',
    giteaApp: '{0} (found the Gitea app automatically)',
    giteaUrl: '{0} (address from the app configuration)',
    giteaBad: 'Gitea does not answer',
    tokenOk: 'The access token works',
    tokenOkDetail: 'Signed in as {0}.',
    tokenBad: 'The access token does not work',
    scopeInstance: 'for the whole Gitea',
    scopeUser: 'for the user of the access token',
    scopeOrganization: 'for the organization {0}',
    scopeRepository: 'for the repository {0}',
    regRegistered: 'The runner “{0}” is registered',
    regStarting: 'Registration is being prepared…',
    regWaiting: 'Waiting for Gitea to answer',
    regNeeds: 'A registration token is needed',
    regNeedsDetail: 'Open the runners page of Gitea, copy the registration token and enter it as “Registration token” in the app configuration. Or enter an access token, then the app fetches the registration token itself. Restart the app afterwards.',
    regRejected: 'Gitea refused the registration',
    regFailed: 'The runner could not be registered',
    runnerUp: 'The runner is connected and waits for jobs',
    runnerUpDetail: 'It takes up to {0} job(s) at a time.',
    runnerBusy: '{0} of {1} jobs are running',
    runnerNotReady: 'The runner is starting or cannot reach Gitea',
    runnerDown: 'The runner is not running',
    remoteOnline: 'Gitea shows the runner as online',
    remoteBusy: 'Gitea shows the runner as online and busy',
    remoteOffline: 'Gitea shows the runner as offline',
    remoteOfflineDetail: 'It can take a minute until Gitea notices a runner that just started.',
    remoteUnknown: 'Gitea’s view of the runner is not available',
    jobsDone: 'Jobs since the app started',
    jobsDoneDetail: '{0} succeeded, {1} failed or cancelled.',
    runnersPage: 'Open the runners page of Gitea',
    openConfig: 'Open app configuration',
    containers: 'Jobs in containers',
    dockerOk: 'Docker engine {0} is reachable',
    dockerOkDetail: 'Jobs run as containers next to your apps and are removed afterwards.',
    dockerBad: 'The app has no access to Docker',
    dockerBadDetail: 'Jobs in containers cannot run.',
    noContainerLabels: 'No labels for jobs in containers',
    noContainerLabelsDetail: 'Choose labels under “labels” in the app configuration to run jobs in containers.',
    labelsHeading: 'Labels, to be used in “runs-on”',
    labelSkipped: 'left out: no Docker',
    imageSlim: 'Slim images: Node.js on Debian, small and quick to download. Good for most workflows.',
    imageStandard: 'Standard images: many build tools included, several hundred megabytes more.',
    imageFull: 'Full images: everything GitHub’s runners have, several gigabytes. Use them only with enough disk space.',
    networkJoined: 'Jobs join the network “{0}”',
    networkJoinedDetail: 'They reach Gitea, Home Assistant and the other apps by name.',
    networkOff: 'Jobs run on a network of their own',
    networkOffDetail: 'They cannot reach the other apps by name. “Join the app network” in the advanced options changes that.',
    addHost: 'The name {0} leads to the Gitea app',
    addHostDetail: 'Gitea announces itself under this name, which only Home Assistant’s own network knows. Jobs get it mapped, so they can clone your repositories.',
    dockerInJobs: 'Jobs may control the Docker engine',
    dockerInJobsDetail: 'This is what building images in a job needs, and it gives the job full control over Home Assistant OS. Use it only for repositories you trust.',
    privileged: 'Jobs run privileged',
    privilegedDetail: 'Same warning as above, even stronger.',
    host: 'Jobs on Home Assistant itself (host mode)',
    hostOff: 'Off',
    hostOffDetail: 'With “host_jobs” switched on, jobs with the label “home-assistant” run inside this app, next to your Home Assistant files. That is how a workflow can change your configuration or reload Home Assistant.',
    hostOn: 'On, label “{0}”',
    hostOnDetail: 'Jobs run as root inside this app. Only let repositories you trust use this runner, for example by registering it for one repository or organization.',
    hostFolders: 'Folders the jobs can use',
    hostFoldersDetail: '{0}. Backup and ssl are read-only.',
    hostApiOn: 'Jobs can use the Home Assistant API',
    hostApiOnDetail: 'The variables SUPERVISOR_TOKEN and HA_API_URL are set for them. The token is visible to every workflow that runs here.',
    hostApiOff: 'Jobs cannot use the Home Assistant API',
    hostApiOffDetail: 'Switch on “home_assistant_api” under “host_jobs” if a workflow should check or reload Home Assistant.',
    tryIt: 'Try it',
    tryIntro: 'Create this file in a repository, push it, and open the “Actions” tab. Actions must be enabled for the repository (Settings → Repository).',
    tryHello: '.gitea/workflows/hello.yaml',
    tryLint: '.gitea/workflows/yamllint.yaml, checks the YAML files of a repository',
    tryReload: '.gitea/workflows/reload.yaml, checks the running Home Assistant and reloads it',
    companions: 'Works well with',
    companionState: 'state: {0}',
    tipMcp: 'Claude and Assist can look at your workflow runs and start them through the toolset “actions”. Leave it in the toolsets of the MCP app.',
    tipGitExporter: 'Every export is a push, so a workflow with “on: push” starts by itself after each export.',
    tipRsyncLocal: 'Files a host job writes to /share are copied to your USB drive with the rest of your data.',
    reason_host_unknown: 'the host name is unknown',
    reason_refused: 'the connection was refused (is the app started?)',
    reason_timeout: 'the request timed out',
    reason_tls: 'the TLS certificate is not trusted (see the advanced options)',
    reason_failed: 'the connection failed (curl error {rc})',
    m_no_answer: 'Gitea does not answer: {reason}.',
    m_login_required: 'Gitea requires a login for everything; the access token decides what the app may check.',
    m_not_gitea: '{url} answers, but it does not look like Gitea (HTTP {http}). Check the address.',
    m_token_rejected: 'Gitea does not accept this access token.',
    m_token_http: 'The token could not be checked (HTTP {http}).',
    m_token_unreachable: 'The token could not be checked because Gitea is not reachable.',
    m_registered: 'The runner is registered.',
    m_waiting: 'Gitea does not answer yet. The app tries again by itself.',
    m_needs_credentials: 'Enter a registration token (or an access token) in the app configuration.',
    m_registration_token_rejected: 'Gitea does not accept this registration token. Copy a fresh one from the runners page of Gitea.',
    m_access_token_rejected: 'Gitea does not accept the access token.',
    m_access_token_scope: 'The access token may not create runner registration tokens for this scope. It needs administrator rights, or the write permission for organizations or repositories.',
    m_scope_not_found: 'Gitea has nothing to register runners for this scope ({scope} “{target}”): check “target” and that Actions are enabled in Gitea.',
    m_registration_http: 'Gitea answered the request for a registration token with HTTP {http}.',
    m_register_failed: 'The runner could not be registered: {detail}',
    m_docker_no_socket: 'The Docker socket is not available. Switch off “Protection mode” on the Info tab of this app and restart it.',
    m_docker_no_answer: 'The Docker engine does not answer on its socket.',
    m_token_scope: 'Gitea does not let this access token look at runners; it needs administrator rights or the matching read permission.',
    m_runner_gone: 'Gitea does not know this runner (any more). With an access token the app registers it again at the next start.',
    m_runner_http: 'Gitea answered the runner check with HTTP {http}.',
    m_no_gitea: 'No Gitea was found. Install the Gitea app, or enter the address of your Gitea in “Gitea address”.',
    m_bad_gitea_url: 'The Gitea address “{url}” is not a web address. Use the form http://homeassistant.local:3000.',
    m_ca_missing: 'The certificate file “{name}” was not found in the /ssl folder.',
    m_bad_target: 'The scope “{scope}” needs a matching “target” (organization name, or owner/repository); “{target}” does not fit.',
    m_bad_runner_name: 'The runner name “{name}” may only hold letters, digits, blanks, dots, dashes and underscores.',
    m_bad_label: 'The label “{label}” is not valid. Use name, name:host or name:docker://image.',
    m_no_labels: 'There is nothing the runner could run: switch on “host_jobs”, or give the app Docker access and choose labels.',
    m_host_label_ignored: 'The label “{label}” runs jobs inside this app and is ignored while “host_jobs” is switched off.',
    m_docker_unavailable: 'The Docker engine is not available, so {count} label(s) for jobs in containers are left out. Switch off “Protection mode” of this app and restart it.',
    m_network_missing: 'The Docker network “{network}” does not exist; jobs run on a network of their own.',
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
    notices: 'Gut zu wissen',
    runner: 'Runner',
    noGitea: 'Kein Gitea eingerichtet',
    noGiteaDetail: 'Installiere die Gitea-App oder trage die Adresse deines Gitea in der App-Konfiguration ein.',
    giteaOk: 'Gitea {0} ist erreichbar',
    giteaApp: '{0} (Gitea-App automatisch gefunden)',
    giteaUrl: '{0} (Adresse aus der App-Konfiguration)',
    giteaBad: 'Gitea antwortet nicht',
    tokenOk: 'Der Zugriffstoken funktioniert',
    tokenOkDetail: 'Angemeldet als {0}.',
    tokenBad: 'Der Zugriffstoken funktioniert nicht',
    scopeInstance: 'für das ganze Gitea',
    scopeUser: 'für den Benutzer des Zugriffstokens',
    scopeOrganization: 'für die Organisation {0}',
    scopeRepository: 'für das Repository {0}',
    regRegistered: 'Der Runner „{0}“ ist registriert',
    regStarting: 'Die Registrierung wird vorbereitet…',
    regWaiting: 'Warte darauf, dass Gitea antwortet',
    regNeeds: 'Ein Registrierungstoken wird gebraucht',
    regNeedsDetail: 'Öffne die Runner-Seite von Gitea, kopiere den Registrierungstoken und trage ihn in der App-Konfiguration als „Registrierungstoken“ ein. Oder trage einen Zugriffstoken ein, dann holt die App den Registrierungstoken selbst. Starte die App danach neu.',
    regRejected: 'Gitea hat die Registrierung abgelehnt',
    regFailed: 'Der Runner konnte nicht registriert werden',
    runnerUp: 'Der Runner ist verbunden und wartet auf Jobs',
    runnerUpDetail: 'Er übernimmt bis zu {0} Job(s) gleichzeitig.',
    runnerBusy: '{0} von {1} Jobs laufen',
    runnerNotReady: 'Der Runner startet oder erreicht Gitea nicht',
    runnerDown: 'Der Runner läuft nicht',
    remoteOnline: 'Gitea zeigt den Runner als online',
    remoteBusy: 'Gitea zeigt den Runner als online und beschäftigt',
    remoteOffline: 'Gitea zeigt den Runner als offline',
    remoteOfflineDetail: 'Es kann eine Minute dauern, bis Gitea einen frisch gestarteten Runner bemerkt.',
    remoteUnknown: 'Die Sicht von Gitea auf den Runner ist nicht verfügbar',
    jobsDone: 'Jobs seit dem Start der App',
    jobsDoneDetail: '{0} erfolgreich, {1} fehlgeschlagen oder abgebrochen.',
    runnersPage: 'Runner-Seite von Gitea öffnen',
    openConfig: 'App-Konfiguration öffnen',
    containers: 'Jobs in Containern',
    dockerOk: 'Docker-Engine {0} ist erreichbar',
    dockerOkDetail: 'Jobs laufen als Container neben deinen Apps und werden danach entfernt.',
    dockerBad: 'Die App hat keinen Zugriff auf Docker',
    dockerBadDetail: 'Jobs in Containern können nicht laufen.',
    noContainerLabels: 'Keine Labels für Jobs in Containern',
    noContainerLabelsDetail: 'Wähle unter „labels“ in der App-Konfiguration Labels, um Jobs in Containern auszuführen.',
    labelsHeading: 'Labels, für „runs-on“',
    labelSkipped: 'ausgelassen: kein Docker',
    imageSlim: 'Schlanke Images: Node.js auf Debian, klein und schnell geladen. Genügt für die meisten Workflows.',
    imageStandard: 'Standard-Images: viele Build-Werkzeuge enthalten, einige hundert Megabyte mehr.',
    imageFull: 'Volle Images: alles, was die Runner von GitHub haben, mehrere Gigabyte. Nur mit genug Speicherplatz verwenden.',
    networkJoined: 'Jobs treten dem Netzwerk „{0}“ bei',
    networkJoinedDetail: 'Sie erreichen Gitea, Home Assistant und die anderen Apps über deren Namen.',
    networkOff: 'Jobs laufen in einem eigenen Netzwerk',
    networkOffDetail: 'Sie erreichen die anderen Apps nicht über deren Namen. „Dem App-Netzwerk beitreten“ in den erweiterten Optionen ändert das.',
    addHost: 'Der Name {0} führt zur Gitea-App',
    addHostDetail: 'Gitea nennt sich unter diesem Namen, den nur das eigene Netzwerk von Home Assistant kennt. Die Jobs bekommen ihn zugeordnet und können so deine Repositories klonen.',
    dockerInJobs: 'Jobs dürfen die Docker-Engine steuern',
    dockerInJobsDetail: 'Das braucht man, um in einem Job Images zu bauen, und es gibt dem Job volle Kontrolle über Home Assistant OS. Nutze es nur für Repositories, denen du vertraust.',
    privileged: 'Jobs laufen privilegiert',
    privilegedDetail: 'Dieselbe Warnung wie oben, noch stärker.',
    host: 'Jobs auf Home Assistant selbst (Host-Modus)',
    hostOff: 'Aus',
    hostOffDetail: 'Ist „host_jobs“ eingeschaltet, laufen Jobs mit dem Label „home-assistant“ in dieser App, direkt neben deinen Home-Assistant-Dateien. So kann ein Workflow deine Konfiguration ändern oder Home Assistant neu laden.',
    hostOn: 'An, Label „{0}“',
    hostOnDetail: 'Jobs laufen als root in dieser App. Lass nur Repositories, denen du vertraust, diesen Runner nutzen, zum Beispiel indem du ihn nur für ein Repository oder eine Organisation registrierst.',
    hostFolders: 'Ordner, die die Jobs nutzen können',
    hostFoldersDetail: '{0}. Backup und ssl sind schreibgeschützt.',
    hostApiOn: 'Jobs können die Home-Assistant-API nutzen',
    hostApiOnDetail: 'Für sie sind die Variablen SUPERVISOR_TOKEN und HA_API_URL gesetzt. Der Token ist für jeden Workflow sichtbar, der hier läuft.',
    hostApiOff: 'Jobs können die Home-Assistant-API nicht nutzen',
    hostApiOffDetail: 'Schalte „home_assistant_api“ unter „host_jobs“ ein, wenn ein Workflow Home Assistant prüfen oder neu laden soll.',
    tryIt: 'Ausprobieren',
    tryIntro: 'Lege diese Datei in einem Repository an, pushe sie und öffne den Reiter „Actions“. Actions müssen für das Repository aktiviert sein (Einstellungen → Repository).',
    tryHello: '.gitea/workflows/hello.yaml',
    tryLint: '.gitea/workflows/yamllint.yaml, prüft die YAML-Dateien eines Repositorys',
    tryReload: '.gitea/workflows/reload.yaml, prüft das laufende Home Assistant und lädt es neu',
    companions: 'Passt gut zu',
    companionState: 'Status: {0}',
    tipMcp: 'Claude und Assist können deine Workflow-Läufe ansehen und starten, über die Werkzeuggruppe „actions“. Lass sie in den Werkzeuggruppen der MCP-App.',
    tipGitExporter: 'Jeder Export ist ein Push, ein Workflow mit „on: push“ startet daher nach jedem Export von selbst.',
    tipRsyncLocal: 'Dateien, die ein Host-Job nach /share schreibt, werden mit deinen übrigen Daten auf dein USB-Laufwerk kopiert.',
    reason_host_unknown: 'der Hostname ist unbekannt',
    reason_refused: 'die Verbindung wurde abgelehnt (läuft die App?)',
    reason_timeout: 'die Anfrage hat das Zeitlimit überschritten',
    reason_tls: 'dem TLS-Zertifikat wird nicht vertraut (siehe Erweitert)',
    reason_failed: 'die Verbindung ist fehlgeschlagen (curl-Fehler {rc})',
    m_no_answer: 'Gitea antwortet nicht: {reason}.',
    m_login_required: 'Gitea verlangt für alles eine Anmeldung; der Zugriffstoken bestimmt, was die App prüfen darf.',
    m_not_gitea: '{url} antwortet, sieht aber nicht nach Gitea aus (HTTP {http}). Prüfe die Adresse.',
    m_token_rejected: 'Gitea akzeptiert diesen Zugriffstoken nicht.',
    m_token_http: 'Der Token konnte nicht geprüft werden (HTTP {http}).',
    m_token_unreachable: 'Der Token konnte nicht geprüft werden, weil Gitea nicht erreichbar ist.',
    m_registered: 'Der Runner ist registriert.',
    m_waiting: 'Gitea antwortet noch nicht. Die App versucht es von selbst wieder.',
    m_needs_credentials: 'Trage in der App-Konfiguration einen Registrierungstoken (oder einen Zugriffstoken) ein.',
    m_registration_token_rejected: 'Gitea akzeptiert diesen Registrierungstoken nicht. Kopiere einen frischen von der Runner-Seite in Gitea.',
    m_access_token_rejected: 'Gitea akzeptiert den Zugriffstoken nicht.',
    m_access_token_scope: 'Der Zugriffstoken darf für diesen Bereich keine Registrierungstoken für Runner erstellen. Er braucht Administratorrechte oder die Schreibberechtigung für Organisationen bzw. Repositories.',
    m_scope_not_found: 'Gitea kennt für diesen Bereich ({scope} „{target}“) keine Runner-Registrierung: Prüfe „target“ und ob Actions in Gitea aktiviert sind.',
    m_registration_http: 'Gitea hat die Anfrage nach einem Registrierungstoken mit HTTP {http} beantwortet.',
    m_register_failed: 'Der Runner konnte nicht registriert werden: {detail}',
    m_docker_no_socket: 'Der Docker-Socket ist nicht verfügbar. Schalte den „Schutzmodus“ auf dem Info-Reiter dieser App aus und starte sie neu.',
    m_docker_no_answer: 'Die Docker-Engine antwortet nicht auf ihrem Socket.',
    m_token_scope: 'Gitea erlaubt diesem Zugriffstoken nicht, Runner anzusehen; er braucht Administratorrechte oder die passende Leseberechtigung.',
    m_runner_gone: 'Gitea kennt diesen Runner nicht (mehr). Mit einem Zugriffstoken registriert die App ihn beim nächsten Start neu.',
    m_runner_http: 'Gitea hat die Runner-Prüfung mit HTTP {http} beantwortet.',
    m_no_gitea: 'Es wurde kein Gitea gefunden. Installiere die Gitea-App oder trage die Adresse deines Gitea unter „Gitea-Adresse“ ein.',
    m_bad_gitea_url: 'Die Gitea-Adresse „{url}“ ist keine Webadresse. Nutze die Form http://homeassistant.local:3000.',
    m_ca_missing: 'Die Zertifikatsdatei „{name}“ wurde im Ordner /ssl nicht gefunden.',
    m_bad_target: 'Der Bereich „{scope}“ braucht ein passendes „target“ (Organisationsname oder Besitzer/Repository); „{target}“ passt nicht.',
    m_bad_runner_name: 'Der Runner-Name „{name}“ darf nur Buchstaben, Ziffern, Leerzeichen, Punkte, Bindestriche und Unterstriche enthalten.',
    m_bad_label: 'Das Label „{label}“ ist ungültig. Nutze name, name:host oder name:docker://image.',
    m_no_labels: 'Der Runner hätte nichts auszuführen: Schalte „host_jobs“ ein, oder gib der App Docker-Zugriff und wähle Labels.',
    m_host_label_ignored: 'Das Label „{label}“ führt Jobs in dieser App aus und wird ignoriert, solange „host_jobs“ ausgeschaltet ist.',
    m_docker_unavailable: 'Die Docker-Engine ist nicht verfügbar, deshalb werden {count} Label(s) für Jobs in Containern ausgelassen. Schalte den „Schutzmodus“ dieser App aus und starte sie neu.',
    m_network_missing: 'Das Docker-Netzwerk „{network}“ existiert nicht; Jobs laufen in einem eigenen Netzwerk.',
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

function field(label, value, rows) {
  const input = el('textarea', { readOnly: true, rows, value });
  return el('div', { className: 'field' }, el('label', {}, label), el('div', { className: 'line' }, input, copyButton(input)));
}

function link(href, text, primary) {
  return el('a', { href, target: '_blank', rel: 'noopener', className: primary ? 'button primary' : 'button' }, text);
}

function banner(id, title, details, lines) {
  const node = document.getElementById(id);
  node.hidden = lines.length === 0;
  const messages = details && details.length ? details.map((entry) => explain(entry)) : lines;
  node.replaceChildren(el('h2', {}, title), ...messages.map((line) => el('p', {}, line)));
}

// ---- runner ------------------------------------------------------------------------------------

function scopeText(registration) {
  return {
    instance: () => t('scopeInstance'),
    user: () => t('scopeUser'),
    organization: () => t('scopeOrganization', registration.target),
    repository: () => t('scopeRepository', registration.target),
  }[registration.scope]();
}

function giteaRows(status) {
  const gitea = status.gitea;
  if (!gitea.url) return [row('bad', t('noGitea'), t('noGiteaDetail'))];

  const source = gitea.source.startsWith('app:') ? 'giteaApp' : 'giteaUrl';
  const rows = [gitea.reachable
    ? row('ok', t('giteaOk', gitea.version || ''), t(source, gitea.url))
    : row('bad', t('giteaBad'), `${gitea.url}: ${explain(gitea)}`)];
  if (gitea.token && gitea.token.state === 'ok') rows.push(row('ok', t('tokenOk'), t('tokenOkDetail', gitea.token.login)));
  else if (gitea.token && gitea.token.state !== 'none') rows.push(row('bad', t('tokenBad'), explain(gitea.token)));
  return rows;
}

function registrationRow(status) {
  const registration = status.registration;
  const detail = explain(registration);
  switch (registration.state) {
    case 'registered': return row('ok', t('regRegistered', registration.name), scopeText(registration));
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

  const remote = runner.remote;
  if (remote.state === 'online') rows.push(row('ok', t(remote.busy ? 'remoteBusy' : 'remoteOnline')));
  else if (remote.state === 'offline') rows.push(row('warn', t('remoteOffline'), t('remoteOfflineDetail')));
  else if (remote.code) rows.push(row('warn', t('remoteUnknown'), explain(remote)));

  if (runner.jobs_succeeded + runner.jobs_failed > 0) {
    rows.push(row('ok', t('jobsDone'), t('jobsDoneDetail', runner.jobs_succeeded, runner.jobs_failed)));
  }
  return rows;
}

function renderRunner(status) {
  const buttons = [
    status.gitea.runners_page && link(status.gitea.runners_page, t('runnersPage')),
    link(`https://my.home-assistant.io/redirect/supervisor_addon/?addon=${status.app.hostname.replace(/-/g, '_')}`, t('openConfig')),
  ];
  document.getElementById('runner').replaceChildren(
    el('h2', {}, t('runner')),
    ...giteaRows(status), registrationRow(status), ...runnerRows(status),
    el('div', { className: 'actions' }, ...buttons));
}

// ---- jobs in containers ------------------------------------------------------------------------

function labelList(labels) {
  return el('ul', { className: 'labels' }, labels.map((label) => el('li', { className: label.skipped ? 'skipped' : '' },
    label.image ? `${label.name} → ${label.image}` : label.name,
    label.skipped ? ` (${t('labelSkipped')})` : '')));
}

function renderContainers(status) {
  const dockerLabels = status.jobs.labels.filter((label) => label.kind === 'docker');
  const rows = [status.docker.available
    ? row('ok', t('dockerOk', status.docker.version), t('dockerOkDetail'))
    : row(dockerLabels.length ? 'bad' : 'warn', t('dockerBad'), `${explain(status.docker)} ${t('dockerBadDetail')}`)];

  if (dockerLabels.length === 0) {
    rows.push(row('warn', t('noContainerLabels'), t('noContainerLabelsDetail')));
  } else {
    rows.push(el('h3', {}, t('labelsHeading')), labelList(dockerLabels));
    const imageNote = { slim: 'imageSlim', standard: 'imageStandard', full: 'imageFull' }[status.jobs.image];
    rows.push(el('p', { className: 'muted' }, t(imageNote)));
    if (status.docker.available && status.jobs.network) {
      rows.push(row('ok', t('networkJoined', status.jobs.network), t('networkJoinedDetail')));
    } else if (status.docker.available) {
      rows.push(row('warn', t('networkOff'), t('networkOffDetail')));
    }
    if (status.jobs.add_host) rows.push(row('ok', t('addHost', status.jobs.add_host.split(':')[0]), t('addHostDetail')));
    if (status.jobs.docker_in_jobs) rows.push(row('warn', t('dockerInJobs'), t('dockerInJobsDetail')));
    if (status.jobs.privileged) rows.push(row('warn', t('privileged'), t('privilegedDetail')));
  }
  document.getElementById('containers').replaceChildren(el('h2', {}, t('containers')), ...rows);
}

// ---- jobs on Home Assistant itself --------------------------------------------------------------

function renderHost(status) {
  const card = document.getElementById('host');
  if (!status.host.enabled) {
    card.replaceChildren(el('h2', {}, t('host')), row('ok', t('hostOff'), t('hostOffDetail')));
    return;
  }
  const folders = status.host.folders.map((folder) => `${folder.path} (${folder.name})`).join(', ');
  card.replaceChildren(
    el('h2', {}, t('host')),
    row('warn', t('hostOn', 'home-assistant'), t('hostOnDetail')),
    row('ok', t('hostFolders'), t('hostFoldersDetail', folders)),
    status.host.home_assistant_api
      ? row('warn', t('hostApiOn'), t('hostApiOnDetail'))
      : row('ok', t('hostApiOff'), t('hostApiOffDetail')));
}

// ---- examples and companions ---------------------------------------------------------------------

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

function workflowLint(label) {
  return [
    'name: YAML lint',
    'on: [push, pull_request]',
    'jobs:',
    '  lint:',
    `    runs-on: ${label}`,
    '    steps:',
    '      - uses: actions/checkout@v4',
    '      - run: |',
    '          apt-get update -qq && apt-get install -y -qq yamllint',
    '          yamllint -d relaxed .',
  ].join('\n');
}

function workflowReload() {
  return [
    'name: Reload Home Assistant',
    'on: [push]',
    'jobs:',
    '  reload:',
    '    runs-on: home-assistant',
    '    steps:',
    '      - name: Check the configuration',
    '        run: |',
    '          curl -fsS -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" \\',
    '            "$HA_API_URL/config/core/check_config" | tee check.json',
    '          grep -q \'"result": *"valid"\' check.json',
    '      - name: Reload everything that can be reloaded',
    '        run: |',
    '          curl -fsS -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" \\',
    '            "$HA_API_URL/services/homeassistant/reload_all"',
  ].join('\n');
}

function renderTry(status) {
  const usable = status.jobs.labels.filter((label) => !label.skipped);
  const containerLabel = usable.find((label) => label.kind === 'docker');
  const first = usable.length ? usable[0].name : 'home-assistant';
  const examples = [field(t('tryHello'), workflowHello(first), 9)];
  if (containerLabel) examples.push(field(t('tryLint'), workflowLint(containerLabel.name), 11));
  if (status.host.enabled && status.host.home_assistant_api) examples.push(field(t('tryReload'), workflowReload(), 14));
  document.getElementById('try').replaceChildren(el('h2', {}, t('tryIt')), el('p', {}, t('tryIntro')), ...examples);
}

function renderCompanions(status) {
  const card = document.getElementById('companions');
  card.hidden = status.companions.length === 0;
  const tips = { mcp: 'tipMcp', git_exporter: 'tipGitExporter', rsync_local: 'tipRsyncLocal' };
  card.replaceChildren(
    el('h2', {}, t('companions')),
    ...status.companions.map((app) => row(app.state === 'started' ? 'ok' : 'warn',
      `${app.name} (${t('companionState', app.state)})`, t(tips[app.id]))));
}

// The examples hold text the user may be selecting or copying; they are only drawn again when
// what they are made of changes.
let lastExamples = '';

function render(status) {
  const release = document.getElementById('release');
  const prerelease = status.app.version.includes('-') ? status.app.version.split('-').slice(1).join('-') : '';
  release.hidden = !prerelease;
  release.textContent = t('preRelease', prerelease);
  document.getElementById('checked').textContent = t('checkedAt', new Date(status.checked_at).toLocaleString());
  banner('problems', t('problems'), status.problem_details, status.problems);
  banner('notices', t('notices'), status.notice_details, status.notices);
  renderRunner(status);
  renderContainers(status);
  renderHost(status);
  renderCompanions(status);

  const examples = JSON.stringify([status.jobs.labels, status.host.enabled, status.host.home_assistant_api]);
  if (examples !== lastExamples) {
    lastExamples = examples;
    renderTry(status);
  }
}

async function load(attempt = 0) {
  const reply = await fetch('status.json', { cache: 'no-store' });
  if (reply.ok) return render(await reply.json());
  // The start script writes the status a moment after the page server is up.
  document.getElementById('checked').textContent = t('starting');
  if (attempt < 30) setTimeout(() => load(attempt + 1), 2000);
}

async function recheck() {
  const button = document.getElementById('recheck');
  button.disabled = true;
  button.textContent = t('rechecking');
  try {
    const reply = await fetch('cgi-bin/recheck', { method: 'POST' });
    if (reply.ok) render(await reply.json());
  } finally {
    button.disabled = false;
    button.textContent = t('recheck');
  }
}

// While the page is open, the status refreshes itself: jobs start and end, the runner goes online.
async function refreshQuietly() {
  if (document.visibilityState !== 'visible') return;
  try {
    const reply = await fetch('cgi-bin/recheck', { method: 'POST' });
    if (reply.ok) render(await reply.json());
  } catch {
    // The next round tries again.
  }
}

document.getElementById('recheck').textContent = t('recheck');
document.getElementById('recheck').addEventListener('click', recheck);
document.title = 'Gitea Runner';
load();
setInterval(refreshQuietly, 15000);
