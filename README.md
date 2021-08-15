# Containerized Shibboleth SP

Pneuma Solutions developed this infrastructure to enable SSO support in [Scribe for Meetings](https://scribeformeetings.com/). It is loosely based on [TIER's Shibboleth SP container](https://github.internet2.edu/docker/shib-sp), but stripped down and based on Red Hat UBI.

In addition to Apache httpd and the Shibboleth SP itself, this container includes our own authentication shim and Shibboleth configuration generator. The authentication shim is a simple Python web app using the Flask micro-framework and served via mod_wsgi. We intend to avoid coupling the shim and configuration generator too tightly to our main web application, but there are probably implicit assumptions about the design of that application.

*TODO*: Add more documentation; eliminate implicit dependencies on the design of our specific application.
