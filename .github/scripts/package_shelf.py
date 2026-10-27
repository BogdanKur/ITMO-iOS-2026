from pathlib import Path
import subprocess,zipfile,json

root=Path('SerialShelf')
out=Path('shelf-projects');out.mkdir(exist_ok=True)
for n in range(1,8):
    project=root/f'Lab{n}'
    if n==1:
        # Lab 1 remains a native Swift Package; xed can open Package.swift directly.
        pass
    else:subprocess.run(['xcodegen','generate'],cwd=project,check=True)
    with zipfile.ZipFile(out/f'Lab{n}-project.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in project.rglob('*'):
            if path.is_file() and not any(part in ['.build','.build-video','xcuserdata'] for part in path.parts):
                archive.write(path,str(path.relative_to(project)))
print('Seven standalone projects ready')
