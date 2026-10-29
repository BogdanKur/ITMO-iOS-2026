from pathlib import Path
import subprocess, json, os, zipfile, hashlib

root = Path.cwd()
project = root / 'SerialShelf/Lab8'
out = root / 'shelf-lint-output'
out.mkdir(exist_ok=True)

def run(args, name, check=True):
    result = subprocess.run(args, cwd=project, text=True, capture_output=True)
    (out / name).write_text(result.stdout + result.stderr)
    print(name, 'exit', result.returncode, flush=True)
    if check and result.returncode:
        print((result.stdout + result.stderr)[-6000:], flush=True)
        raise RuntimeError(name)
    return result

run(['swiftlint', 'version'], 'swiftlint-version.txt')
run(['xcodebuild', '-version'], 'Xcode-version.txt')
run(['swiftlint', 'rules', '--config', '.swiftlint.yml'], 'rules.txt')
before = run(['swiftlint', 'lint', '--no-cache', '--reporter', 'json'], 'lint-before.json', False)
(out / 'lint-before.json').write_text(before.stdout)
(out / 'lint-before.log').write_text(before.stderr)
if os.environ.get('APPLY_FIX') == 'true':
    run(['swiftformat', 'Sources', 'Tests', 'UITests'], 'format.log')
    run(['swiftlint', 'lint', '--fix', '--no-cache'], 'autocorrect.log')
result = run(['swiftlint', 'lint', '--strict', '--no-cache', '--reporter', 'json'], 'lint-final.raw.txt', False)
# stdout is valid JSON; diagnostics go to stderr.
(out / 'lint-final.json').write_text(result.stdout)
(out / 'lint-final.log').write_text(result.stderr)
report = json.loads(result.stdout)
files = sorted(p for folder in ['Sources', 'Tests', 'UITests'] for p in (project / folder).rglob('*.swift'))
(out / 'source-hashes.json').write_text(json.dumps({str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}, indent=2))
(out / 'result-status.json').write_text(json.dumps({'lint_exit': result.returncode, 'violations': len(report), 'swift_files': len(files)}, indent=2))
with zipfile.ZipFile(out / 'Lab8-corrected-sources.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in files: archive.write(p, str(p.relative_to(project)))
assert result.returncode == 0, 'SwiftLint violations remain; see lint-final.json'
run(['xcodegen', 'generate'], 'xcodegen.log')
devices = json.loads(run(['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], 'devices.json').stdout)['devices']
phones = [d for runtime, values in devices.items() if 'iOS' in runtime for d in values if 'iPhone' in d['name']]
phone = next((d for d in phones if d['name'] == 'iPhone 16 Pro'), phones[0])
run(['xcrun', 'simctl', 'boot', phone['udid']], 'boot.log', False)
run(['xcrun', 'simctl', 'bootstatus', phone['udid'], '-b'], 'bootstatus.log')
run(['xcodebuild', '-project', 'SerialShelf.xcodeproj', '-scheme', 'SerialShelf', '-destination', 'platform=iOS Simulator,id=' + phone['udid'], '-parallel-testing-enabled', 'NO', '-resultBundlePath', str(out / 'Tests.xcresult'), 'CODE_SIGNING_ALLOWED=NO', 'test'], 'tests.log')
run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(out / 'Tests.xcresult')], 'test-summary.json')
with zipfile.ZipFile(out / 'Lab8-Ready-Project.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in project.rglob('*'):
        if p.is_file() and not any(x in p.parts for x in ['.build', '.idea', 'xcuserdata']):
            archive.write(p, str(p.relative_to(project)))
print('Lint and tests passed', flush=True)
