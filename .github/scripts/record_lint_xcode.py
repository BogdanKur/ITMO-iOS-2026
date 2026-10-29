from pathlib import Path
import subprocess,os,time,json,threading,shutil

root=Path.cwd();project=root/'SerialShelf/Lab8';out=root/'xcode-lint-output';out.mkdir(exist_ok=True)
log=(out/'commands.log').open('w')
def run(args,check=True,cwd=project):
    args=[str(a) for a in args]
    print('$',' '.join(args),flush=True);log.write('$ '+' '.join(args)+'\n');log.flush()
    r=subprocess.run(args,cwd=cwd,text=True,capture_output=True,timeout=300)
    log.write(r.stdout+r.stderr+'\n');log.flush()
    if check and r.returncode:raise RuntimeError((r.stdout+r.stderr)[-6000:])
    return r
def apple(s):return run(['osascript','-e',s],False)
def key(n):apple(f'tell application "System Events" to tell process "Xcode" to key code {n} using {{command down}}')
def snap(n):run(['screencapture','-x',out/(n+'.png')],False)
apps=sorted(Path('/Applications').glob('Xcode_*.app'),key=lambda p:tuple(int(x) for x in p.stem.split('_')[-1].split('.') if x.isdigit()))
run(['sudo','xcode-select','-s',apps[-1]/'Contents/Developer'])
xcode=Path(run(['xcode-select','-p']).stdout.strip()).parents[1]
(out/'Xcode-version.txt').write_text(run(['xcodebuild','-version']).stdout)
(out/'SwiftLint-version.txt').write_text(run(['swiftlint','version']).stdout)
install='Installed SwiftLint\n\n'+run(['which','swiftlint']).stdout+'\n'+run(['swiftlint','version']).stdout+'\n'+run(['brew','list','--versions','swiftlint']).stdout
(project/'SwiftLint-installation.txt').write_text(install)
clean={p:p.read_bytes() for folder in ['Sources','Tests','UITests'] for p in (project/folder).rglob('*.swift')}
def bad():
    for p in clean:
        r=run(['git','show','a03c89a:SerialShelf/Lab8/'+p.relative_to(project).as_posix()],cwd=root)
        p.write_text(r.stdout)
def good():
    for p,data in clean.items():p.write_bytes(data)
# A separate shared scheme checks exactly the application's real Sources/Tests/UITests.
# This aggregate target does not require an iOS Simulator to display lint failures.
spec='''name: Lab8-SwiftLint
fileGroups: [Sources, Tests, UITests, Scripts, .swiftlint.yml, SwiftLint-installation.txt]
targets:
  SwiftLint:
    type: aggregate
    platform: macOS
    deploymentTarget: "15.0"
    preBuildScripts:
      - name: SwiftLint strict validation
        script: |
          export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
          echo "SwiftLint version: $(swiftlint version)"
          bash "$SRCROOT/Scripts/lint.sh"
        basedOnDependencyAnalysis: false
schemes:
  SwiftLint:
    build:
      targets:
        SwiftLint: all
'''
(project/'lint-demo.yml').write_text(spec);run(['xcodegen','generate','--spec','lint-demo.yml'])
proj=project/'Lab8-SwiftLint.xcodeproj'
base=['xcodebuild','-project',proj,'-scheme','SwiftLint','CODE_SIGNING_ALLOWED=NO','build']
bad();r=run(base+['-resultBundlePath',out/'Before.xcresult'],False)
(out/'before-build.log').write_text(r.stdout+r.stderr);assert r.returncode!=0
r=run(['swiftlint','lint','--strict','--no-cache','--reporter','json'],False)
(out/'before.json').write_text(r.stdout);assert len(json.loads(r.stdout))==13
good();r=run(base+['-resultBundlePath',out/'After.xcresult'])
(out/'after-build.log').write_text(r.stdout+r.stderr)
r=run(['swiftlint','lint','--strict','--no-cache','--reporter','json'])
(out/'after.json').write_text(r.stdout);assert json.loads(r.stdout)==[]
bad()
run(['open','-a',xcode],False);time.sleep(7)
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
apple('''tell application "System Events" to tell process "Xcode"
 repeat with label in {"Continue", "Get Started", "Not Now"}
  if exists button (contents of label) of front window then click button (contents of label) of front window
 end repeat
end tell''')
run(['open','-a',xcode,proj]);time.sleep(10)
apple('tell application "Xcode" to activate')
apple('tell application "System Events" to tell process "Xcode" to set position of front window to {0, 25}')
apple('tell application "System Events" to tell process "Xcode" to set size of front window to {1024, 710}')
frames=[];sections=[];stop=threading.Event();frames_dir=out/'frames';frames_dir.mkdir(exist_ok=True);start=time.monotonic()
def now():return time.monotonic()-start
def record():
    while not stop.is_set():
        t=now();name=f'{len(frames):05}.jpg'
        try:
            r=subprocess.run(['screencapture','-x','-t','jpg',str(frames_dir/name)],capture_output=True,timeout=6)
            if r.returncode==0:frames.append(dict(name=name,seconds=t))
        except subprocess.TimeoutExpired:pass
        stop.wait(.5)
thread=threading.Thread(target=record,daemon=True);thread.start()
def hold(label,seconds=7):
    a=now();time.sleep(seconds);snap(f'{len(sections):02}');sections.append(dict(label=label,start=a,end=now()))
def show(path,label=None):
    run(['xed','--line','1',path]);time.sleep(2);key(115);hold(label or path.name)
try:
    apple('tell application "System Events" to tell process "Xcode" to click menu item "About Xcode" of menu "Xcode" of menu bar 1')
    hold('Actual Xcode version',4);apple('tell application "System Events" to tell process "Xcode" to key code 53')
    show(project/'SwiftLint-installation.txt','Installed SwiftLint binary and version')
    show(project/'.swiftlint.yml','SwiftLint configuration')
    show(project/'Scripts/lint.sh','Strict SwiftLint build phase script')
    show(project/'Sources/Presentation/AnalysisViewModel.swift','Original imports with violations')
    # The only shared scheme is SwiftLint, so Cmd+B performs the actual lint build.
    key(98);time.sleep(12);key(53);hold('Xcode Issue Navigator: real SwiftLint errors',10)
    run(['open','-a',xcode,out/'Before.xcresult']);time.sleep(7);hold('Failed build result: before corrections',9)
    good()
    run(['open','-a',xcode,proj]);time.sleep(3)
    show(project/'Sources/Presentation/AnalysisViewModel.swift','Corrected imports')
    show(project/'Sources/Presentation/RemoteViewModels.swift','Corrected error handling layout')
    key(98);time.sleep(10);key(53);hold('Xcode Issue Navigator after corrections',7)
    run(['open','-a',xcode,out/'After.xcresult']);time.sleep(7);hold('Successful strict lint build',9)
finally:
    good();stop.set();thread.join(timeout=8)
(out/'sections.json').write_text(json.dumps(sections,indent=2));(out/'frame-times.json').write_text(json.dumps(frames,indent=2))
concat=[]
for i,f in enumerate(frames):
    concat += ["file 'frames/"+f['name']+"'",'duration '+str(frames[i+1]['seconds']-f['seconds'] if i+1<len(frames) else 1)]
concat += ["file 'frames/"+frames[-1]['name']+"'"]
(out/'frames.ffconcat').write_text('\n'.join(concat))
run(['ffmpeg','-y','-v','error','-f','concat','-safe','0','-i',out/'frames.ffconcat','-vf','fps=15','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',out/'Lab8-Real-Xcode.mp4'])
shutil.rmtree(frames_dir)
(out/'result-status.json').write_text(json.dumps(dict(before_violations=13,after_violations=0,platform='real macOS Xcode',version=install),indent=2))
print('REAL XCODE RECORDING COMPLETE',flush=True)
