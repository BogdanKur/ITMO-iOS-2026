"""Record real Xcode/Simulator windows; output contains no captions or overlays."""
import json, subprocess, sys, threading, time, shutil, os, signal, select
from pathlib import Path

lab = int(sys.argv[1])
root = Path.cwd()
project = root / f'Lab{lab}'
out = root / 'video-output'
out.mkdir(exist_ok=True)
log = (out / 'recording.log').open('w')

def run(args, timeout=60, check=False, cwd=None, name=None):
    command = [str(a) for a in args]
    log.write(time.strftime('%H:%M:%S') + ' START $ ' + ' '.join(command) + '\n'); log.flush()
    print('START', time.strftime('%H:%M:%S'), command, flush=True)
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=cwd, start_new_session=True)
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        p = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
    except subprocess.TimeoutExpired as exc:
        os.killpg(process.pid, signal.SIGKILL)
        try: stdout, stderr = process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            stdout = exc.stdout.decode(errors='replace') if isinstance(exc.stdout, bytes) else exc.stdout or ''
            stderr = exc.stderr.decode(errors='replace') if isinstance(exc.stderr, bytes) else exc.stderr or ''
        p = subprocess.CompletedProcess(command, 124, stdout, stderr + '\nCOMMAND TIMEOUT\n')
    log.write(time.strftime('%H:%M:%S') + ' END\n' + p.stdout + p.stderr + '\n'); log.flush()
    if name: (out / name).write_text(p.stdout + p.stderr)
    print('command', args[0], 'exit', p.returncode, flush=True)
    if check and p.returncode: raise RuntimeError('Command failed: ' + str(args) + '\n' + p.stderr[-1500:])
    return p

def apple(text): return run(['osascript', '-e', text])
def xkey(k, mods='command down'):
    return apple('tell application "System Events" to tell process "Xcode" to keystroke ' + json.dumps(k) + ' using {' + mods + '}')
def snap(name): run(['screencapture', '-x', str(out / (name + '.png'))])
def inspect(name, app='Xcode'):
    p = apple(f'tell application "System Events" to tell process "{app}" to get entire contents of front window')
    (out / (name + '.txt')).write_text(p.stdout + p.stderr)

available = sorted(Path('/Applications').glob('Xcode_*.app'), key=lambda p: tuple(int(x) for x in p.stem.split('_')[-1].split('.') if x.isdigit()))
if available:
    run(['sudo', 'xcode-select', '-s', available[-1] / 'Contents/Developer'], check=True)
version = run(['xcodebuild', '-version'], check=True).stdout
(out / 'Xcode-version.txt').write_text(version + '\n' + run(['sw_vers']).stdout)
assert int(version.split()[1].split('.')[0]) >= 26
run(['swiftc', root / '.github/scripts/NativeScreenRecorder.swift', '-o', root / '.video-screen-recorder'], timeout=120, check=True)
xcode = Path(run(['xcode-select', '-p']).stdout.strip()).parents[1]
simulator = xcode / 'Contents/Developer/Applications/Simulator.app'
devices = json.loads(run(['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], timeout=300, check=True).stdout)['devices']
phones = [d for runtime, values in devices.items() if 'iOS' in runtime for d in values if 'iPhone' in d['name']]
device = next((d for d in phones if d['name'] == 'iPhone 17 Pro'), phones[0])
if lab == 6:
    stable_phones = [d for runtime, values in devices.items() if 'iOS-18-5' in runtime for d in values if 'iPhone' in d['name']]
    if stable_phones: device = next((d for d in stable_phones if d['name'] == 'iPhone 16 Pro'), stable_phones[0])
udid = device['udid']
(out / 'device.json').write_text(json.dumps(device, indent=2))
print('Using', version.strip(), device['name'], flush=True)
run(['xcrun', 'simctl', 'boot', udid])
run(['open', '-a', simulator, '--args', '-CurrentDeviceUDID', udid])
run(['xcrun', 'simctl', 'bootstatus', udid, '-b'], timeout=600, check=True)

# Add only a disposable automation target. Lab sources and existing tests stay unchanged.
if lab != 7:
    driver = project / '.video-ui'; driver.mkdir(exist_ok=True)
    (driver / 'VideoDriver.swift').write_text((root / '.github/scripts/VideoDriver.swift').read_text().replace('LAB_NUMBER', str(lab)))
    spec = (project / 'project.yml').read_text()
    spec = spec.replace('\nschemes:', '''
  VideoDriver:
    type: bundle.ui-testing
    platform: iOS
    sources: [.video-ui]
    dependencies: [{target: StudyNotes}]
schemes:''')
    spec = spec.replace('schemes:\n', '''schemes:
  VideoDemo:
    build:
      targets:
        StudyNotes: all
    test:
      targets: [VideoDriver]
''')
    (project / 'project.yml').write_text(spec)
run(['xcodegen', 'generate'], cwd=project, check=True)
build = project / '.video-build'
base = ['xcodebuild', '-project', project / 'StudyNotes.xcodeproj', '-destination', 'platform=iOS Simulator,id=' + udid,
        '-derivedDataPath', build, '-parallel-testing-enabled', 'NO', 'CODE_SIGNING_ALLOWED=NO']
if lab != 7:
    run(base + ['build-for-testing', '-scheme', 'VideoDemo'], timeout=600, check=True, name='build-demo.log')
run(base + ['build-for-testing', '-scheme', 'StudyNotes'], timeout=600, check=True, name='build-tests.log')

run(['open', '-a', xcode], check=True); time.sleep(8)
apple('tell application "Xcode" to activate')
apple('''tell application "System Events" to tell process "Xcode"
  if exists static text "Select the components you want to get started with:" of group 1 of front window then
    tell group 1 of front window
      repeat with c in every checkbox
        if enabled of c and value of c is 1 then click c
      end repeat
      click last button
    end tell
  end if
end tell''')
time.sleep(4)
apple('''tell application "System Events" to tell process "Xcode"
 repeat with label in {"Continue", "Get Started", "Not Now"}
   if exists button (contents of label) of front window then click button (contents of label) of front window
 end repeat
end tell''')
run(['open', '-a', xcode, project / 'StudyNotes.xcodeproj'], check=True); time.sleep(12)
apple('tell application "Xcode" to activate')
apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')
inspect('xcode-startup')

frame_dir = out / 'frames'; frame_dir.mkdir(exist_ok=True)
stop = threading.Event(); frames = []; sections = []
native_log = (out / 'native-capture.log').open('w')
native = subprocess.Popen([str(root / '.video-screen-recorder'), str(out / 'desktop.mov')], stdout=subprocess.PIPE, stderr=native_log, text=True)
native_ready = bool(select.select([native.stdout], [], [], 60)[0]) and native.stdout.readline().strip() == 'CAPTURE_READY'
if not native_ready:
    native.kill(); native.wait(timeout=10)
start = time.monotonic()
def capture():
    while not stop.is_set():
        t = time.monotonic() - start
        name = f'{len(frames):06}.jpg'
        try:
            p = subprocess.run(['screencapture', '-x', '-t', 'jpg', str(frame_dir / name)], capture_output=True, timeout=5)
            if p.returncode == 0: frames.append({'seconds': t, 'name': name})
        except subprocess.TimeoutExpired: pass
        stop.wait(max(0, 1.0 - (time.monotonic() - start - t)))
worker = None
# Always retain a timestamped backup of the actual desktop.
worker = threading.Thread(target=capture, daemon=True); worker.start()
def now(): return round(time.monotonic() - start, 3)
def hold(label, seconds=6):
    t = now(); time.sleep(seconds); sections.append({'label': label, 'start': t, 'end': now()}); snap(label)
def show(label, path, line=1, seconds=6):
    apple('tell application "Xcode" to activate')
    run(['xed', '--line', str(line), project / path]); time.sleep(3)
    hold(label, seconds)

try:
    apple('tell application "System Events" to tell process "Xcode" to click menu item "About Xcode" of menu "Xcode" of menu bar 1')
    hold('01-Xcode-version', 3)
    apple('tell application "System Events" to tell process "Xcode" to key code 53'); time.sleep(1)
    sources = {
        2: [('02-interface', 'Sources/StudyNotesApp.swift', 5), ('03-navigation', 'Sources/StudyNotesApp.swift', 31), ('04-tests', 'Tests/NumberGeneratorTests.swift', 1)],
        3: [('02-model', 'Sources/Domain/Note.swift', 1), ('03-viewmodel', 'Sources/Presentation/NotesViewModel.swift', 1), ('04-views', 'Sources/Presentation/Views.swift', 15)],
        4: [('02-SwiftData', 'Sources/Data/SwiftDataNoteRepository.swift', 1), ('03-CRUD', 'Sources/Data/SwiftDataNoteRepository.swift', 35), ('04-UserDefaults', 'Sources/Data/SettingsStore.swift', 1)],
        5: [('02-background-work', 'Sources/Domain/NoteAnalysis.swift', 1), ('03-detached-tasks', 'Sources/Presentation/AnalysisViewModel.swift', 12), ('04-main-actor', 'Sources/Presentation/AnalysisView.swift', 1)],
        6: [('02-network', 'Sources/Network/PostsService.swift', 31), ('03-HTTP-errors', 'Sources/Network/PostsService.swift', 50), ('04-GET-POST', 'Sources/Network/PostsService.swift', 75), ('05-interface', 'Sources/Presentation/RemotePostsView.swift', 1)],
        7: [('02-unit-tests', 'Tests/NotesViewModelTests.swift', 1), ('03-unit-errors', 'Tests/NotesViewModelTests.swift', 50), ('04-UI-tests', 'UITests/StudyNotesUITests.swift', 1), ('05-UI-settings', 'UITests/StudyNotesUITests.swift', 60)],
    }[lab]
    for label, path, line in sources: show(label, path, line)
    # Keep the actual editor visible behind the actual Simulator.
    apple('tell application "System Events" to tell process "Xcode" to set size of front window to {660, 710}')
    run(['defaults', 'write', 'com.apple.iphonesimulator', 'SimulatorWindowLastScale', '-float', '0.5'])
    run(['open', '-a', simulator, '--args', '-CurrentDeviceUDID', udid]); time.sleep(5)
    apple('tell application "Simulator" to activate')
    apple('tell application "System Events" to tell process "Simulator" to set position of front window to {660, 26}')
    apple('tell application "System Events" to tell process "Simulator" to set size of front window to {360, 710}')
    inspect('simulator-window', 'Simulator'); snap('06-before-demo')
    demo_start = now()
    scheme = 'StudyNotes' if lab == 7 else 'VideoDemo'
    result = out / ('Lab' + str(lab) + '-demo.xcresult')
    demo = run(base + ['test-without-building', '-scheme', scheme, '-resultBundlePath', result], timeout=600, name='demo-tests.log')
    time.sleep(3)
    sections.append({'label': '07-application-demo', 'start': demo_start, 'end': now()})
    snap('07-after-demo')
    run(['xcrun', 'simctl', 'io', udid, 'screenshot', out / 'Simulator.png'])
    apple('tell application "System Events" to set visible of process "Simulator" to false')
    if lab != 7:
        # Run the lab's own suite separately from the disposable video driver.
        test_result = out / ('Lab' + str(lab) + '-tests.xcresult')
        tests = run(base + ['test-without-building', '-scheme', 'StudyNotes', '-resultBundlePath', test_result], timeout=600, name='lab-tests.log')
    else:
        test_result = result; tests = demo
    run(['open', '-a', xcode, test_result]); time.sleep(10)
    apple('tell application "Xcode" to activate')
    apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
    apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')
    inspect('test-results'); hold('08-test-results', 8)
    (out / 'result-status.json').write_text(json.dumps({'demo': demo.returncode, 'tests': tests.returncode}))
finally:
    stop.set()
    if worker: worker.join(timeout=15)
    if native_ready:
        native.send_signal(signal.SIGUSR1)
        native.wait(timeout=60)
    (out / 'sections.json').write_text(json.dumps(sections, indent=2))
    (out / 'frame-times.json').write_text(json.dumps(frames, indent=2))

if native_ready:
    probe = run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', out / 'desktop.mov'])
    duration = float(probe.stdout.strip() or 0)
    expected = sections[-1]['end'] if sections else 0
    if duration < expected - 5:
        print('Native capture incomplete; using full timestamped desktop backup', duration, expected, flush=True)
        native_ready = False
if native_ready:
    capture_input = ['-i', out / 'desktop.mov']
else:
    assert len(frames) > 30, 'Screen capture failed'
    concat = []
    for i, item in enumerate(frames):
        concat.append("file 'frames/" + item['name'] + "'")
        duration = frames[i+1]['seconds'] - item['seconds'] if i + 1 < len(frames) else 1
        concat.append('duration ' + str(duration))
    concat.append("file 'frames/" + frames[-1]['name'] + "'")
    (out / 'frames.ffconcat').write_text('\n'.join(concat))
    capture_input = ['-f', 'concat', '-safe', '0', '-i', out / 'frames.ffconcat']
run(['ffmpeg', '-y', '-v', 'error'] + capture_input + ['-vf', 'fps=15',
     '-c:v', 'libx264', '-preset', 'fast', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out / f'Lab{lab}-desktop.mp4'], timeout=300, check=True)
verified = run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', out / f'Lab{lab}-desktop.mp4'])
assert float(verified.stdout.strip()) >= sections[-1]['end'] - 3, 'Incomplete encoded desktop video'
# Avoid a large archive of redundant JPEGs; retain the actual video, timing and evidence.
shutil.rmtree(frame_dir)
if (out / 'desktop.mov').exists(): (out / 'desktop.mov').unlink()
for p in out.glob('*.xcresult'):
    run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', p], name=p.stem + '-summary.json')
    shutil.rmtree(p)
(out / 'README.txt').write_text(f'Actual Xcode and iPhone Simulator on macOS. Lab {lab}. No captions, no replacement UI.\n' + version)
assert demo.returncode == 0, 'Application demonstration failed; see demo-tests.log and desktop video'
assert tests.returncode == 0, 'Lab tests failed; see lab-tests.log and desktop video'
print('RECORDING COMPLETE', lab, len(frames), 'frames', flush=True)
