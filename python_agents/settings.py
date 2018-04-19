"""Settings for the different MOX agents included in this bundle."""
import os

DIR = os.path.dirname(__file__)

# Settings
# Use environment variable or fallback value

# Environ wrapper
env = os.environ.get

# System settings
AMQP_SERVER = env('MOX_AMQP_HOST', 'localhost')

# Agent settings
MOX_ADVIS_QUEUE = env('MOX_ADVIS_QUEUE', 'Advis')
MOX_LOG_EXCHANGE = env('MOX_LOG_EXCHANGE', 'mox.log')
MOX_OBJECT_EXCHANGE = env('MOX_OBJECT_EXCHANGE', 'mox.rest')

IS_LOG_AUTHENTICATION_ENABLED = env('MOX_LOG_AUTHENTICATION_ENABLED', False)

OIOREST_SERVER = env('MOX_OIO_REST_URI', 'https://localhost')

# Default system email
FROM_EMAIL = env('MOX_EMAIL_REPLY_ADDRESS', 'mox-advis@noreply.magenta.dk')
ADVIS_SUBJECT_PREFIX = '[MOX-ADVIS]'

# Log files
MOX_ADVIS_LOG_FILE = env('MOX_ADVIS_LOG_FILE', '/var/log/mox/mox-advis.log')
MOX_ELK_LOG_FILE = env('MOX_ELK_LOG_FILE', '/var/log/mox/mox-elk.log')
DO_LOG_TO_AMQP = env('MOX_ENABLE_LOG_TO_AMQP', True)

# Saml settings
SAML_IDP_ENTITY_ID = env('MOX_SAML_IDP_ENTITY_ID', 'localhost')
SAML_MOX_ENTITY_ID = env('MOX_SAML_MOX_ENTITY_ID', 'https://localhost')

# Legacy
TEST_PUBLIC_KEY = os.path.join(DIR, 'test_auth_data/idp-certificate.pem')
SAML_IDP_CERTIFICATE = env('MOX_SAML_IDP_CERTIFICATE', TEST_PUBLIC_KEY)

# Logstash settings
MOX_LOGSTASH_URI = env('MOX_LOGSTASH_URI', 'http://127.0.0.1:42998')
MOX_LOGSTASH_USER = env('MOX_LOGSTASH_USER', 'mox_logstash_user')
MOX_LOGSTASH_PASS = env('MOX_LOGSTASH_PASS', 'secretlogstashpassword')