"""Real macOS screen recording; whole-file tours with readable overlapping scrolls."""
from pathlib import Path
import os, subprocess, json, time, signal, threading, math, shutil, select, sys

lab = int(sys.argv[1])
root = Path.cwd()
project = root / 'SerialShelf' / f'Lab{lab}'
out = root / 'shelf-output'
out.mkdir(exist_ok=True)
log = (out / 'commands.log').open('w')
record = os.environ.get('RECORD_VIDEO', 'true').lower() == 'true'

def run(args, timeout=90, check=True, name=None, cwd=None):
    command = [str(x) for x in args]
    print(time.strftime('%H:%M:%S'), '$', ' '.join(command), flush=True)
    log.write('$ ' + ' '.join(command) + '\n'); log.flush()
    process = subprocess.Popen(command, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
    try: stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        stdout, stderr = process.communicate(timeout=15)
        stderr += '\nTIMEOUT\n'
    log.write(stdout + stderr + '\n'); log.flush()
    if name: (out / name).write_text(stdout + stderr)
    if check and process.returncode:
        raise RuntimeError('Command failed: ' + str(command) + '\n' + (stdout + stderr)[-6000:])
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)

def apple(script): return run(['osascript','-e',script], check=False, timeout=40)
def xkey(key): apple('tell application "System Events" to tell process "Xcode" to keystroke ' + json.dumps(key) + ' using {command down}')
def snap(name): run(['screencapture','-x',out/(name+'.png')], check=False, timeout=10)

apps=sorted(Path('/Applications').glob('Xcode_*.app'),key=lambda p:tuple(int(x) for x in p.stem.split('_')[-1].split('.') if x.isdigit()))
run(['sudo','xcode-select','-s',apps[-1]/'Contents/Developer'])
version=run(['xcodebuild','-version'],name='Xcode-version.txt').stdout
xcode=Path(run(['xcode-select','-p']).stdout.strip()).parents[1]
simulator=xcode/'Contents/Developer/Applications/Simulator.app'
run(['sw_vers'], name='macOS-version.txt')

if lab == 1:
    spec='''name: Lab1
settings:
  base:
    SWIFT_VERSION: "5.0"
    CODE_SIGNING_ALLOWED: NO
    GENERATE_INFOPLIST_FILE: YES
targets:
  Lab1Core:
    type: framework
    platform: macOS
    deploymentTarget: "15.0"
    sources: [Sources/Lab1Core]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: edu.itmo.lab1.core
  Lab1Demo:
    type: tool
    platform: macOS
    deploymentTarget: "15.0"
    sources: [Sources/Lab1Demo]
    dependencies: [{target: Lab1Core}]
  Lab1CoreTests:
    type: bundle.unit-test
    platform: macOS
    deploymentTarget: "15.0"
    sources: [Tests/Lab1CoreTests]
    dependencies: [{target: Lab1Core}]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: edu.itmo.lab1.tests
schemes:
  Lab1Demo:
    build:
      targets:
        Lab1Demo: all
    run:
      executable: Lab1Demo
    test:
      targets: [Lab1CoreTests]
'''
    (project/'project.yml').write_text(spec)
    scheme='Lab1Demo'; filename='Lab1.xcodeproj'
    destination=['-destination','platform=macOS']
else:
    # A separate recording target drives UI; it is not part of the delivered labs.
    driver=project/'.recording-driver';driver.mkdir(exist_ok=True)
    (driver/'ShelfVideoDriver.swift').write_text((root/'.github/scripts/ShelfVideoDriver.swift').read_text().replace('LAB_NUMBER',str(lab)))
    spec=(project/'project.yml').read_text()
    spec=spec.replace('\nschemes:', '''
  ShelfVideoDriver:
    type: bundle.ui-testing
    platform: iOS
    sources: [.recording-driver]
    dependencies: [{target: SerialShelf}]
schemes:''')
    spec=spec.replace('schemes:\n','''schemes:
  ShelfVideo:
    build:
      targets:
        SerialShelf: all
    test:
      targets: [ShelfVideoDriver]
''')
    (project/'project.yml').write_text(spec)
    devices=json.loads(run(['xcrun','simctl','list','devices','available','-j'],timeout=300).stdout)['devices']
    phones=[d for runtime,values in devices.items() if 'iOS-18-5' in runtime for d in values if 'iPhone' in d['name']]
    if not phones: phones=[d for runtime,values in devices.items() if 'iOS' in runtime for d in values if 'iPhone' in d['name']]
    phone=next((d for d in phones if d['name']=='iPhone 16 Pro'),phones[0]);udid=phone['udid']
    run(['xcrun','simctl','boot',udid],check=False)
    run(['open','-a',simulator,'--args','-CurrentDeviceUDID',udid],check=False)
    run(['xcrun','simctl','bootstatus',udid,'-b'],timeout=600)
    destination=['-destination','platform=iOS Simulator,id='+udid]
    scheme='SerialShelf';filename='SerialShelf.xcodeproj'

run(['xcodegen','generate'],cwd=project)
base=['xcodebuild','-project',project/filename,'-derivedDataPath',project/'.build-video','-parallel-testing-enabled','NO','CODE_SIGNING_ALLOWED=NO']+destination
result=out/'Tests.xcresult'
run(base+['test','-scheme',scheme,'-resultBundlePath',result],timeout=900,name='tests.log')
run(['xcrun','xcresulttool','get','test-results','summary','--path',result],name='test-summary.json')
run(['xcrun','xccov','view','--report',result],check=False,name='coverage.txt')
if lab!=1:
    run(base+['build-for-testing','-scheme','ShelfVideo'],timeout=600,name='build-demo.log')
    shutil.make_archive(str(out/f'Lab{lab}-simulator'),'zip',project/'.build-video/Build/Products/Debug-iphonesimulator','SerialShelf.app')
if not record:
    print('BUILD AND TESTS COMPLETE',lab,flush=True)
    sys.exit(0)

run(['swiftc',root/'.github/scripts/NativeScreenRecorder.swift','-o',out/'recorder'],timeout=180)
scroll='''import AppKit
let point = CGPoint(x: 760, y: 390)
CGEvent(mouseEventSource:nil, mouseType:.mouseMoved, mouseCursorPosition:point, mouseButton:.left)?.post(tap:.cghidEventTap)
Thread.sleep(forTimeInterval:0.1)
for _ in 0..<12 {
 CGEvent(scrollWheelEvent2Source:nil, units:.pixel, wheelCount:1, wheel1:-25, wheel2:0, wheel3:0)?.post(tap:.cghidEventTap)
 Thread.sleep(forTimeInterval:0.035)
}
'''
(out/'scroll.swift').write_text(scroll)
run(['swiftc',out/'scroll.swift','-o',out/'scroll'],timeout=120)
run(['open','-a',xcode],check=False);time.sleep(8)
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
time.sleep(5)
apple('''tell application "System Events" to tell process "Xcode"
 repeat with label in {"Continue", "Get Started", "Not Now"}
  if exists button (contents of label) of front window then click button (contents of label) of front window
 end repeat
end tell''')
run(['open','-a',xcode,project/filename]);time.sleep(12)
apple('tell application "Xcode" to activate')
apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')

frames=[];stop=threading.Event();sections=[]
frames_dir=out/'frames';frames_dir.mkdir(exist_ok=True)
native_log=(out/'capture.log').open('w')
native=subprocess.Popen([str(out/'recorder'),str(out/'desktop.mov')],stdout=subprocess.PIPE,stderr=native_log,text=True)
native_ready=bool(select.select([native.stdout],[],[],60)[0]) and native.stdout.readline().strip()=='CAPTURE_READY'
if not native_ready:native.kill();native.wait(timeout=10)
start=time.monotonic()
def now():return round(time.monotonic()-start,3)
def backup():
    while not stop.is_set():
        t=now();name=f'{len(frames):06}.jpg'
        try:
            p=subprocess.run(['screencapture','-x','-t','jpg',str(frames_dir/name)],timeout=5,capture_output=True)
            if p.returncode==0:frames.append({'seconds':t,'name':name})
        except subprocess.TimeoutExpired:pass
        stop.wait(0.75)
thread=threading.Thread(target=backup,daemon=True);thread.start()
def section(label,a):sections.append({'label':label,'start':a,'end':now()})
try:
    a=now()
    apple('tell application "System Events" to tell process "Xcode" to click menu item "About Xcode" of menu "Xcode" of menu bar 1')
    time.sleep(3);snap('version');section('Xcode version',a)
    apple('tell application "System Events" to tell process "Xcode" to key code 53')
    # Every delivered Swift source and test is shown from beginning to end.
    files=sorted([p for directory in ['Sources','Tests','UITests'] for p in (project/directory).rglob('*.swift')])
    if lab==1:files=[project/'Package.swift']+files
    manifest=[]
    for index,path in enumerate(files):
        run(['xed','--line','1',path]);time.sleep(2)
        apple('tell application "System Events" to tell process "Xcode" to key code 115 using {command down}')
        time.sleep(.5)
        a=now()
        text=path.read_text();logical=len(text.splitlines())
        wrapped=sum(max(1,math.ceil(len(line)/86)) for line in text.splitlines())
        # 300 px ~ 17 lines; use conservative steps and leave a 5-second hold per page.
        pages=max(1,math.ceil(max(0,wrapped-27)/15)+1)
        for page in range(pages):
            time.sleep(4.5)
            snap(f'file-{index:02}-page-{page:02}')
            if page<pages-1:run([out/'scroll'],check=False,timeout=10)
        time.sleep(1)
        section(str(path.relative_to(project)),a)
        manifest.append({'file':str(path.relative_to(project)),'lines':logical,'pages':pages,'start':a,'end':now()})
    (out/'file-manifest.json').write_text(json.dumps(manifest,indent=2))
    if lab==1:
        run(['xed',project/'Sources/Lab1Demo/main.swift']);time.sleep(2)
        a=now();xkey('r');time.sleep(12);snap('app-result');section('Run Lab1Demo',a)
        run(['swift','run','Lab1Demo'],cwd=project,name='demo-output.txt',timeout=120)
    else:
        apple('tell application "System Events" to tell process "Xcode" to set size of front window to {660, 710}')
        run(['open','-a',simulator,'--args','-CurrentDeviceUDID',udid]);time.sleep(4)
        apple('tell application "Simulator" to activate')
        apple('tell application "System Events" to tell process "Simulator" to set position of front window to {660, 26}')
        apple('tell application "System Events" to tell process "Simulator" to set size of front window to {360, 710}')
        a=now()
        demo=run(base+['test-without-building','-scheme','ShelfVideo','-resultBundlePath',out/'Demo.xcresult'],timeout=700,check=False,name='demo.log')
        section('Application demonstration',a);snap('app-result')
        (out/'demo-status.txt').write_text(str(demo.returncode))
        apple('tell application "System Events" to set visible of process "Simulator" to false')
    run(['open','-a',xcode,result]);time.sleep(8)
    apple('tell application "Xcode" to activate')
    apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
    apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')
    a=now();time.sleep(8);snap('test-results');section('XCTest results',a)
finally:
    stop.set();thread.join(timeout=10)
    if native_ready:
        native.send_signal(signal.SIGUSR1)
        try:native.wait(timeout=60)
        except subprocess.TimeoutExpired:native.kill()
    (out/'sections.json').write_text(json.dumps(sections,indent=2))
    (out/'frame-times.json').write_text(json.dumps(frames,indent=2))

duration=0
if (out/'desktop.mov').exists():
    value=run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1',out/'desktop.mov'],check=False).stdout
    try:duration=float(value)
    except ValueError:pass
if duration>=sections[-1]['end']-4:
    source=['-i',out/'desktop.mov']
else:
    assert len(frames)>50
    concat=[]
    for i,item in enumerate(frames):
        concat.append("file 'frames/"+item['name']+"'")
        concat.append('duration '+str(frames[i+1]['seconds']-item['seconds'] if i+1<len(frames) else 1))
    concat.append("file 'frames/"+frames[-1]['name']+"'")
    (out/'frames.ffconcat').write_text('\n'.join(concat))
    source=['-f','concat','-safe','0','-i',out/'frames.ffconcat']
run(['ffmpeg','-y','-v','error']+source+['-vf','fps=15','-an','-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',out/f'Lab{lab}-full.mp4'],timeout=600)
# Keep originals until local quality review; upload video and evidence, not raw JPEGs/results.
for path in out.glob('*.xcresult'):shutil.rmtree(path)
shutil.rmtree(frames_dir)
if (out/'desktop.mov').exists():(out/'desktop.mov').unlink()
for name in ['recorder','scroll','scroll.swift']:
    (out/name).unlink(missing_ok=True)
print('READY',lab,'FILES',len(files),'SECTIONS',len(sections),flush=True)
