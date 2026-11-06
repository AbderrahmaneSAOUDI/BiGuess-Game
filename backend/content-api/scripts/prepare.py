"""Validate an exported archive completely before a trusted publisher signs it."""
import base64
import io
import json
from pathlib import Path
import sys
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))
from export_pack import canonical_json, unique_json, invalid_constant, validate_manifest
from validate_content_contract import validate


def prepare(path):
    data = Path(path).read_bytes()
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate archive entries')
        manifest_bytes = archive.read('manifest.json')
        manifest = json.loads(manifest_bytes, object_pairs_hook=unique_json,
                              parse_constant=invalid_constant)
        validate('PublicManifest', manifest)
        if canonical_json(manifest) != manifest_bytes:
            raise ValueError('Noncanonical manifest')
        objects = {row['key']: archive.read(row['key']) for row in manifest['objects']}
        if set(names) != {'manifest.json', *objects}:
            raise ValueError('Unexpected archive entries')
        for entry in archive.infolist():
            if entry.is_dir() or (entry.external_attr >> 16) != 0o100644:
                raise ValueError('Nonregular archive entry')
        validate_manifest(manifest, objects)  # Includes actual decoded image format.
    return {"manifest": base64.b64encode(manifest_bytes).decode(),
            "archive": base64.b64encode(data).decode(),
            "objects": {key: base64.b64encode(value).decode() for key, value in objects.items()}}


if __name__ == '__main__':
    print(json.dumps(prepare(sys.argv[1]), separators=(',', ':')))
