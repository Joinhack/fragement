import sae

from gmweb import init

init("sae")

from gmweb import app

application = sae.create_wsgi_app(app)
