import subprocess,time,json,threading
from pathlib import Path

out=Path('video-output');out.mkdir(exist_ok=True)
def run(args,timeout=50,check=False,cwd=None):
    p=subprocess.run(args,capture_output=True,text=True,timeout=timeout,cwd=cwd)
    print('$',' '.join(str(x) for x in args),'\n',p.stdout,p.stderr,flush=True)
    if check and p.returncode:raise RuntimeError(p.stderr)
    return p
def apple(script):return run(['osascript','-e',script])
def snap(name):run(['screencapture','-x',str(out/name)])
def key(k,mods='command down'):
    apple('tell application "System Events" to tell process "Xcode" to keystroke '+json.dumps(k)+' using {'+mods+'}')
def menu(top,item):
    apple(f'tell application "System Events" to tell process "Xcode" to click menu item {json.dumps(item)} of menu {json.dumps(top)} of menu bar 1')
def inspect(name):
    value=apple('tell application "System Events" to tell process "Xcode" to get entire contents of front window').stdout
    (out/name).write_text(value)
def open_file(path,line=1):
    run(['xed','--line',str(line),str(Path(path).resolve())])
    time.sleep(2)

def expand_console():
    apple('tell application "System Events" to tell process "Xcode" to get name of menu items of menu 1 of menu item "Debug Area" of menu "View" of menu bar 1')

version=run(['xcodebuild','-version'],check=True).stdout
(out/'Xcode-version.txt').write_text(version+'\n'+run(['sw_vers']).stdout)
app=Path(run(['xcode-select','-p']).stdout.strip()).parents[1]
assert int(version.split()[1].split('.')[0])>=26,version
# Disposable Xcode project: the Swift package sources remain unchanged.
spec='''name: Lab1
options:
  deploymentTarget:
    macOS: "15.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
    CODE_SIGNING_ALLOWED: NO
    GENERATE_INFOPLIST_FILE: YES
targets:
  Lab1Core:
    type: framework
    platform: macOS
    sources: [Sources/Lab1Core]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: edu.itmo.lab1.core
  Lab1Demo:
    type: tool
    platform: macOS
    sources: [Sources/Lab1Demo]
    dependencies: [{target: Lab1Core}]
  Lab1CoreTests:
    type: bundle.unit-test
    platform: macOS
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
Path('Lab1/project.yml').write_text(spec)
run(['xcodegen','generate'],cwd='Lab1',check=True)
mouse='''import AppKit
let start = CGPoint(x: 820, y: 601)
CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: start, mouseButton: .left)?.post(tap: .cghidEventTap)
for i in 1...30 {
    let point = CGPoint(x: 820, y: 601 - Double(i) * 7.0)
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.02)
}
CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: 820, y: 391), mouseButton: .left)?.post(tap: .cghidEventTap)
'''
(out/'drag-console.swift').write_text(mouse)
run(['swiftc',str(out/'drag-console.swift'),'-o',str(out/'drag-console')],check=True)
run(['open','-a',str(app)],check=True)
time.sleep(8)
apple('tell application "Xcode" to activate')
inspect('startup.txt')
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
inspect('after-components.txt')
apple('''tell application "System Events" to tell process "Xcode"
 repeat with label in {"Continue", "Get Started", "Not Now"}
   if exists button (contents of label) of front window then click button (contents of label) of front window
 end repeat
end tell''')
run(['open','-a',str(app),str(Path('Lab1/Lab1.xcodeproj').resolve())],check=True)
time.sleep(12)
apple('tell application "Xcode" to activate')
inspect('project-window.txt');snap('01-project.png')
apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')
open_file('Lab1/Sources/Lab1Demo/main.swift')
snap('02-editor.png');inspect('editor-window.txt')
timeline=[]
def mark(label):timeline.append({'seconds':round(time.monotonic()-started,2),'label':label})
frames_dir=out/'frames';frames_dir.mkdir(exist_ok=True)
stop_capture=threading.Event();frame_times=[]
started=time.monotonic()
def capture_frames():
    while not stop_capture.is_set():
        t=time.monotonic()-started
        name=f'frame-{len(frame_times):06}.jpg'
        p=subprocess.run(['screencapture','-x','-t','jpg',str(frames_dir/name)],capture_output=True)
        if p.returncode==0:frame_times.append({'seconds':t,'name':name})
        stop_capture.wait(max(0,0.25-(time.monotonic()-started-t)))
worker=threading.Thread(target=capture_frames);worker.start();time.sleep(2)
mark('Xcode version')
menu('Xcode','About Xcode');time.sleep(5);snap('03-about.png')
apple('tell application "System Events" to tell process "Xcode" to key code 53');time.sleep(1)
mark('Main entry point')
open_file('Lab1/Sources/Lab1Demo/main.swift');time.sleep(7)
mark('Order analytics')
open_file('Lab1/Sources/Lab1Core/Orders.swift',12);time.sleep(9);snap('04-orders.png')
mark('Point and Rectangle')
open_file('Lab1/Sources/Lab1Core/Geometry.swift');time.sleep(10);snap('05-geometry.png')
mark('Custom priority queue')
open_file('Lab1/Sources/Lab1Core/PriorityQueue.swift');time.sleep(10);snap('06-queue.png')
mark('Run Lab1Demo in Xcode')
open_file('Lab1/Sources/Lab1Demo/main.swift');key('r');time.sleep(22)
expand_console()
snap('07-run.png');inspect('after-run.txt')
mark('Unit tests')
open_file('Lab1/Tests/Lab1CoreTests/Lab1Tests.swift');time.sleep(8);key('u');time.sleep(28)
snap('08-tests.png');inspect('after-test.txt')
mark('Test navigator')
key('6');time.sleep(9);snap('09-navigator.png')
mark('Program output')
open_file('Lab1/Sources/Lab1Demo/main.swift');key('r');time.sleep(12);snap('10-final.png')
demo=run(['swift','run','Lab1Demo'],cwd='Lab1',timeout=90)
Path('Lab1/DemoOutput.txt').write_text(demo.stdout)
(out/'demo-output.txt').write_text(demo.stdout+demo.stderr)
mark('Saved console output')
open_file('Lab1/DemoOutput.txt');time.sleep(10);snap('11-output.png')
mark('End')
(out/'timeline.json').write_text(json.dumps(timeline,indent=2))
stop_capture.set();worker.join(timeout=10)
(out/'frame-times.json').write_text(json.dumps(frame_times,indent=2))
assert len(frame_times)>100,'Insufficient captured frames'
tests=run(['swift','test'],cwd='Lab1',timeout=180)
(out/'swift-tests.txt').write_text(tests.stdout+tests.stderr)
demo=run(['swift','run','Lab1Demo'],cwd='Lab1',timeout=60)
(out/'demo-output.txt').write_text(demo.stdout+demo.stderr)
run(['zip','-r',str((out/'Lab1-Xcode-project.zip').resolve()),'Lab1.xcodeproj','project.yml','Sources','Tests','Package.swift'],cwd='Lab1')
print('Recording finished',flush=True)
