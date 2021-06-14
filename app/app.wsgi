import os
import time
import urllib.parse

from flask import Flask, redirect, request

import jwt

app = Flask(__name__)


@app.route("/", methods=["GET"])
def shim():
    claims = {"exp": int(time.time() + 300)}
    environ = request.environ
    print(environ)
    idp = environ.get("Shib-Identity-Provider")
    if idp:
        claims["idp"] = idp
    uid = environ.get("REMOTE_USER")
    if uid:
        claims["sub"] = uid
    local_id = environ.get("sfm_local_id")
    if local_id:
        claims["local_id"] = local_id
    email = environ.get("mail")
    if email:
        claims["email"] = email.split(";")[0]
    entitlements = environ.get("entitlement")
    if entitlements:
        claims["entitlements"] = entitlements.split(";")
    member_of = environ.get("member_of")
    if member_of:
        claims["member_of"] = member_of.split(";")
    token = jwt.encode(claims, os.environ["SAML_SHIM_SECRET"], "HS256")
    return redirect("/auth/saml/callback?token=%s&state=%s" % (urllib.parse.quote(token), urllib.parse.quote(request.args.get("state", ""))))


application = app
