import subprocess,os,time,json
from pathlib import Path

out=Path('video-output');out.mkdir(exist_ok=True)
def run(args,timeout=50,check=False):
    p=subprocess.run(args,capture_output=True,text=True,timeout=timeout)
    print('$',' '.join(str(x) for x in args),'\n',p.stdout,p.stderr,flush=True)
    if check and p.returncode:raise RuntimeError(p.stderr)
    return p
def apple(script):return run(['osascript','-e',script])
def snap(name):run(['screencapture','-x',str(out/name)])

available=sorted(Path('/Applications').glob('Xcode_*.app'),key=lambda p:tuple(int(x) for x in p.stem.split('_')[-1].split('.') if x.isdigit()))
if available:
    run(['sudo','xcode-select','-s',str(available[-1]/'Contents/Developer')],check=True)
version=run(['xcodebuild','-version'],check=True).stdout
(out/'Xcode-version.txt').write_text(version+'\n'+run(['sw_vers']).stdout)
app=Path(run(['xcode-select','-p']).stdout.strip()).parents[1]
run(['screencapture','-h'])
run(['system_profiler','SPDisplaysDataType'])
apple('tell application "System Events" to get UI elements enabled')
run(['open','-a',str(app),str(Path('Lab1/Package.swift').resolve())],check=True)
time.sleep(20)
apple('tell application "Xcode" to activate')
apple('tell application "System Events" to tell process "Xcode" to get {name, size, position} of every window')
apple('tell application "System Events" to tell process "Xcode" to get name of every menu bar item of menu bar 1')
snap('01-xcode.png')
apple('tell application "Xcode" to get version')
apple('tell application "System Events" to tell process "Xcode" to click menu item "About Xcode" of menu "Xcode" of menu bar 1')
time.sleep(2)
snap('02-about.png')
record=run(['screencapture','-x','-v','-V','5',str(out/'probe.mov')],timeout=20)
(out/'probe-result.txt').write_text(record.stdout+record.stderr)
apple('tell application "System Events" to tell process "Xcode" to get entire contents of front window')
print('Probe complete',flush=True)
