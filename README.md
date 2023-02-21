# openpgp-interop-test-docker

A docker image to run the openpgp interoperability test suite, with a few implementations pre installed.

# Test suite

The test suite is provided by sequoia: https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite

It calls to each implementation using the SOP (stateless openpgp) interface.  

## Preinstalled implementations

### sqop

SOP implementation with sequoia-openpgp as the backend.

https://gitlab.com/sequoia-pgp/sequoia-sop

https://gitlab.com/sequoia-pgp/sequoia

### gosop

SOP implementation with gopenpgp as the backend.

https://github.com/ProtonMail/gosop

https://github.com/ProtonMail/gopenpgp

### gpgme-sop

SOP implementation using gnupg as the backend, via gpgme.

https://gitlab.com/sequoia-pgp/gpgme-sop

https://gnupg.org/software/gpgme/index.html

https://gnupg.org/

### sop-openpgpjs

SOP implementation using openpgp.js as the backend.

https://github.com/openpgpjs/sop-openpgpjs

https://github.com/openpgpjs/openpgpjs

### rnp-sop

SOP implementations using RNP as the backend

https://gitlab.com/sequoia-pgp/rnp-sop

https://github.com/rnpgp/rnp