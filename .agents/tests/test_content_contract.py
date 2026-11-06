"""T19 language-neutral schemas, OpenAPI, positive and incompatible wire vectors."""
import copy
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
import zipfile

from jsonschema import Draft202012Validator, ValidationError
from openapi_spec_validator import OpenAPIV31SpecValidator

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts'))
import export_pack as exporter
import validate_content_contract as contract

FIXTURES = contract.CONTRACT / 'fixtures'


def fixture(name):
    return json.loads((FIXTURES / (name + '.json')).read_text())


class ContentContractTests(unittest.TestCase):
    def test_schema_and_openapi_are_valid_and_references_resolve(self):
        Draft202012Validator.check_schema(contract.SCHEMA)
        spec = json.loads((contract.CONTRACT / 'openapi.json').read_text())
        OpenAPIV31SpecValidator(spec, base_uri=(contract.CONTRACT / 'openapi.json').as_uri()).validate()
        # Resolve every local schema reference offline, including request/response types.
        def walk(value):
            if isinstance(value, dict):
                if '$ref' in value:
                    target = value['$ref']
                    self.assertIn(target.split('#')[0], ('', './schemas.json'))
                    node = contract.SCHEMA
                    for key in target.split('#/')[1].split('/'):
                        node = node[key]
                for child in value.values():
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)
        walk(spec)
        walk(contract.SCHEMA)

    def test_all_positive_fixtures(self):
        for path in FIXTURES.glob('*.json'):
            if path.name == 'invalid.json':
                continue
            with self.subTest(path=path.name):
                example = json.loads(path.read_text())
                contract.validate(example['type'], example['payload'])

    def test_portable_incompatible_vectors(self):
        for case in json.loads((FIXTURES / 'invalid.json').read_text()):
            with self.subTest(case=case):
                example = json.loads((FIXTURES / case['fixture']).read_text())
                node = example['payload']
                parts = case['pointer'].strip('/').split('/')
                for part in parts[:-1]:
                    node = node[int(part)] if isinstance(node, list) else node[part]
                key = int(parts[-1]) if isinstance(node, list) else parts[-1]
                node[key] = case['value']
                with self.assertRaises((ValidationError, ValueError)):
                    contract.validate(example['type'], example['payload'])

    def test_frozen_manifest_matches_real_exporter_and_download_hashes(self):
        source = REPO / 'test/fixtures/cleared_shapes/pack.json'
        manifest, archive = exporter.build_pack(source.parent, *exporter.fixture_source(source), revision=2)
        self.assertEqual(fixture('manifest')['payload'], manifest)
        download = fixture('download')['payload']
        self.assertEqual(download['manifestSha256'], exporter.sha256(exporter.canonical_json(manifest)))
        self.assertEqual(download['archiveSha256'], exporter.sha256(archive))
        self.assertEqual(download['sizeBytes'], len(archive))
        with zipfile.ZipFile(io.BytesIO(archive)) as container:
            objects = {k: container.read(k) for k in container.namelist() if k != 'manifest.json'}
        exporter.validate_manifest(manifest, objects)
        key = next(iter(objects))
        objects[key] += b'tampered'
        with self.assertRaises(exporter.PackError):
            exporter.validate_manifest(manifest, objects)

    def test_delta_reconstructs_target_without_unchanged_image_transport(self):
        target = fixture('manifest')['payload']
        baseline = fixture('delta-base-manifest')['payload']
        delta = fixture('delta')['payload']
        contract.validate('Manifest', baseline)
        contract.validate('Delta', delta)
        self.assertEqual(baseline['pack']['revision'], delta['fromRevision'])
        self.assertEqual(target['pack']['revision'], delta['toRevision'])
        cards = {c['id']: c for c in baseline['cards']}
        for card_id in delta['removeCardIds']:
            self.assertIn(card_id, cards)
            del cards[card_id]
        for card in delta['upsertCards']:
            cards[card['id']] = card
        self.assertEqual(sorted(cards.values(), key=lambda c: c['id']), target['cards'])
        self.assertEqual([], delta['objects'])
        self.assertEqual(baseline['objects'], target['objects'])
        self.assertEqual(exporter.sha256(exporter.canonical_json(target)), delta['targetManifestSha256'])

    def test_required_fields_cannot_be_omitted(self):
        for path in FIXTURES.glob('*.json'):
            if path.name == 'invalid.json':
                continue
            example = json.loads(path.read_text())
            for field in example['payload']:
                value = copy.deepcopy(example['payload'])
                del value[field]
                with self.subTest(fixture=path.name, field=field), self.assertRaises(ValidationError):
                    contract.validate(example['type'], value)

    def test_revision_results_are_complete_and_monotonic(self):
        request = fixture('revision-request')['payload']
        response = fixture('revision-response')['payload']
        contract.validate_revision_results(request, response)
        for change in ('missing', 'duplicate', 'stale_update', 'stale_delete', 'wrong_unchanged'):
            value = copy.deepcopy(response)
            if change == 'missing': value['results'].pop()
            if change == 'duplicate': value['results'].append(value['results'][0])
            if change == 'stale_update': value['results'][0]['revision'] = 1
            if change == 'stale_delete': value['results'][1]['tombstone']['revision'] = 2
            if change == 'wrong_unchanged': value['results'][3]['revision'] = 3
            with self.subTest(change=change), self.assertRaises(ValueError):
                contract.validate_revision_results(request, value)

    def test_duplicate_catalog_and_batch_ids_fail(self):
        for name, field in [('topics', 'items'), ('packs', 'items'), ('studio-batch', 'operations')]:
            example = fixture(name)
            example['payload'][field].append(copy.deepcopy(example['payload'][field][0]))
            with self.subTest(name=name), self.assertRaises(ValueError):
                contract.validate(example['type'], example['payload'])

    def test_cli_rejects_duplicate_keys_and_non_json_constants(self):
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'invalid.json'
            for raw in ['{"protocolVersion":1,"protocolVersion":2}', '{"revision":NaN}']:
                path.write_text(raw)
                result = subprocess.run([sys.executable, str(REPO / 'scripts/validate_content_contract.py'),
                                         'TopicPage', str(path)], capture_output=True, text=True)
                self.assertNotEqual(0, result.returncode)

    def test_request_and_response_schemas_are_plain_json(self):
        spec = json.loads((contract.CONTRACT / 'openapi.json').read_text())
        self.assertEqual([], spec['security'])
        studio = spec['paths']['/studio/batches']['post']
        self.assertEqual([{'StudioBearer': []}], studio['security'])
        self.assertTrue(any(p['name'] == 'Idempotency-Key' and p['required'] for p in studio['parameters']))
        self.assertEqual(set(contract.SCHEMA['$defs']['Card']['properties']),
                         {'id', 'packId', 'name', 'imageReference', 'difficulty'})
