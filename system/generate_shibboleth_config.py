#!/usr/bin/env python3.8
import hashlib
import hmac
import json
import os
import string
import sys
import time
import urllib.request


def write_file(path, content):
    tmp_path = f"{path}.tmp"
    with open(tmp_path, "w") as f:
        f.write(content)
    os.rename(tmp_path, path)


prev_encoded_response = None


def run():
    global prev_encoded_response
    endpoint_host = os.environ["ENDPOINT_HOST"]
    support_contact = os.environ["SUPPORT_CONTACT"]
    secret = os.environ["SAML_SHIM_SECRET"]
    token = hmac.new(secret.encode("utf-8"), b"sso_config", "md5").hexdigest()
    url = f"https://{endpoint_host}/api/sso/config/{token}"
    encoded = urllib.request.urlopen(url).read()
    if encoded == prev_encoded_response:
        return
    prev_encoded_response = encoded
    json_object = json.loads(encoded)
    metadata_filter_includes = []
    org_attribute_map_fragments = []
    for org in json_object["orgs"]:
        idp_entity_id = org["idp_entity_id"]
        idp_metadata = org.get("idp_metadata")
        if idp_metadata and idp_metadata.strip():
            idp_entity_id_hash = hashlib.new(
                "sha1", idp_entity_id.encode("utf-8")
            ).hexdigest()
            path = "/etc/shibboleth/adhoc-md/%s.xml" % idp_entity_id_hash
            if not os.path.exists(path):
                write_file(path, idp_metadata)
        else:
            metadata_filter_includes.append(f"<Include>{idp_entity_id}</Include>")
        attribute_map_fragment = org.get("attribute_map_fragment")
        if attribute_map_fragment:
            org_attribute_map_fragments.append(attribute_map_fragment)
    shibboleth_template = open("/etc/shibboleth/shibboleth2.xml.tmpl", "r").read()
    shibboleth_conf = string.Template(shibboleth_template).substitute(
        endpoint_host=endpoint_host,
        support_contact=support_contact,
        metadata_filter_includes="".join(metadata_filter_includes),
    )
    write_file("/etc/shibboleth/shibboleth2.xml", shibboleth_conf)
    attribute_map_template = open("/etc/shibboleth/attribute-map.xml.tmpl", "r").read()
    attribute_map = string.Template(attribute_map_template).substitute(
        org_attribute_map_fragments="".join(org_attribute_map_fragments)
    )
    write_file("/etc/shibboleth/attribute-map.xml", attribute_map)


def main():
    if "--loop" in sys.argv:
        while True:
            time.sleep(60)
            run()
    else:
        run()


if __name__ == "__main__":
    main()
