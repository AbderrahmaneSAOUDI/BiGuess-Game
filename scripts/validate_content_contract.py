#!/usr/bin/env python3
"""Reference v1 wire validator; no Flutter, database, backend or network required."""
import argparse
import json
from pathlib import Path
import sys

from jsonschema import Draft202012Validator, FormatChecker, ValidationError

sys.path.insert(0, str(Path(__file__).resolve().parent))
from export_pack import identifier, text, unique_json, invalid_constant, PackError

CONTRACT = Path(__file__).resolve().parents[1] / 'contracts/content/v1'
SCHEMA = json.loads((CONTRACT / 'schemas.json').read_text())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def unique(rows, key):
    values = [row[key] for row in rows]
    require(len(values) == len(set(values)), f'Duplicate {key}')


def validate(kind, payload):
    """Validate structure plus relationships JSON Schema cannot express.

    Byte hashes/image decoding and stateful preconditions require the artifact
    validator and server/client state respectively; see the normative README.
    """
    require(kind in SCHEMA['$defs'], 'Unknown contract type')
    schema = {**SCHEMA, '$ref': '#/$defs/' + kind}
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(payload)

    def scalars(value, key=''):
        if isinstance(value, dict):
            for k, v in value.items():
                scalars(v, k)
        elif isinstance(value, list):
            for v in value:
                scalars(v, key)
        elif isinstance(value, str):
            value.encode('utf-8')
            if key in ('id', 'packId', 'topicId', 'actorId', 'requestId'):
                identifier(value)
            elif key == 'name':
                text(value, key)
        # Reject booleans and fractional/float encodings at the Python boundary,
        # matching the existing full-Pack reader rather than silently coercing.
        elif key in ('revision', 'fromRevision', 'toRevision', 'sizeBytes', 'difficulty',
                     'cardCount', 'protocolVersion', 'schemaVersion', 'manifestSchemaVersion'):
            require(type(value) is int, f'{key} must be an integer token')
    scalars(payload)

    if kind in ('TopicPage', 'PackPage'):
        unique(payload['items'], 'id')
    if kind == 'RevisionRequest':
        unique(payload['packs'], 'packId')
    if kind == 'RevisionResponse':
        unique(payload['results'], 'packId')
        for result in payload['results']:
            if result['status'] == 'deleted':
                require(result['packId'] == result['tombstone']['packId'], 'Tombstone Pack mismatch')
    if kind in ('Manifest', 'PublicManifest', 'Delta'):
        cards = payload['cards'] if kind in ('Manifest', 'PublicManifest') else payload['upsertCards']
        pack_id = payload['pack']['id'] if kind in ('Manifest', 'PublicManifest') else payload['packId']
        unique(cards, 'id')
        unique(payload['objects'], 'key')
        require(all(c['packId'] == pack_id for c in cards), 'Card Pack mismatch')
        for image in payload['objects']:
            ext = {'image/webp': 'webp', 'image/png': 'png', 'image/jpeg': 'jpg'}[image['mediaType']]
            require(image['key'] == f"objects/{image['sha256']}.{ext}", 'Image key/hash/type mismatch')
        if kind in ('Manifest', 'PublicManifest'):
            require(payload['pack']['topicId'] == payload['topic']['id'], 'Topic mismatch')
            require({c['imageReference'] for c in cards} == {o['key'] for o in payload['objects']}, 'Missing/unused object')
            p = payload['provenance']
            if p['mode'] == 'cleared-test':
                unique(p['cardRights'], 'id')
                require([r['id'] for r in p['cardRights']] == sorted(r['id'] for r in p['cardRights']), 'Unsorted rights')
                require({r['id'] for r in p['cardRights']} == {c['id'] for c in cards}, 'Card rights mismatch')
            require([c['id'] for c in cards] == sorted(c['id'] for c in cards), 'Unsorted Cards')
            require([o['key'] for o in payload['objects']] == sorted(o['key'] for o in payload['objects']), 'Unsorted objects')
        else:
            require(payload['toRevision'] > payload['fromRevision'], 'Delta must advance revision')
            require(not ({c['id'] for c in cards} & set(payload['removeCardIds'])), 'Conflicting Card operations')
            require({o['key'] for o in payload['objects']} <= {c['imageReference'] for c in cards}, 'Unused delta object')
    if kind == 'StudioBatch':
        aggregate = payload['aggregate']
        seen = set()
        for operation in payload['operations']:
            identity = (operation['resourceType'], operation['id'])
            require(identity not in seen, 'One operation per resource per batch')
            seen.add(identity)
            if operation['resourceType'] == aggregate['resourceType']:
                require(operation['id'] == aggregate['id'], 'Aggregate ID mismatch')
            else:
                require(aggregate['resourceType'] == 'pack' and operation['resourceType'] == 'card', 'Cross-aggregate batch')
            if operation['resourceType'] == 'card' and 'value' in operation:
                require(operation['value']['packId'] == aggregate['id'], 'Cross-Pack Card mutation')
    return payload


def validate_revision_results(request, response):
    validate('RevisionRequest', request)
    validate('RevisionResponse', response)
    known = {p['packId']: p['revision'] for p in request['packs']}
    require(set(known) == {p['packId'] for p in response['results']}, 'Missing/unrequested revision result')
    for result in response['results']:
        if result['status'] == 'unchanged':
            require(result['revision'] == known[result['packId']], 'Unchanged revision mismatch')
        if result['status'] == 'updateAvailable':
            require(result['revision'] > known[result['packId']], 'Update must advance revision')
        if result['status'] == 'deleted':
            require(result['tombstone']['revision'] > known[result['packId']], 'Stale tombstone')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('type', choices=SCHEMA['$defs'])
    parser.add_argument('payload', type=Path)
    args = parser.parse_args()
    payload = json.loads(args.payload.read_text(encoding='utf-8'), object_pairs_hook=unique_json,
                         parse_constant=invalid_constant)
    validate(args.type, payload)
    print(f'{args.type}: valid')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, PackError, ValidationError) as error:
        sys.exit(str(error))
