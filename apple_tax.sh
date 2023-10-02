#!/bin/bash

# SPDX-License-Identifier: MIT
# Andy Maloney <asmaloney@gmail.com>

# This was put together using a whole bunch of online sources since Apple's docs are
# incomplete:
#   https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow

# This script requires that you have created an application-specific password from Aapple for
# "notarytool", and that it & your Apple Developer Application credentials are in your keychain.
# See the README for details.

# Example: ./apple_tax.sh MyApp.app

# Example with entitlements: ./apple_tax.sh MyApp.app entitlements.plist
# NOTE: I'm not currently using entitlements, so that path is untested.

TARGET_APP="$(readlink -f "${1}")"
ENTITLEMENTS_FILE="$(readlink -f "${2}")"
ZIP_NAME="${TARGET_APP}.zip"

# This should be your developer ID for applications & it should be in your keychain.
SIGNING_ID="Developer ID Application: COMPANY (TEAM_ID)"
NOTARIZATION_KEYCHAIN="notarytool"

echo "Application: ${TARGET_APP}"

function signApplication()
{
  TARGET_APP="${1}"
  SIGNING_ID="${2}"
  ENTITLEMENTS_FILE="${3}"

  echo "** Signing: ${TARGET_APP}"

  if [ ! -e "${TARGET_APP}" ]; then
      echo "ERROR: Cannot find application: ${TARGET_APP}"
      exit
  fi

  ADD_ENTITLEMENTS=
  if [ -e "${ENTITLEMENTS_FILE}" ]; then
    ADD_ENTITLEMENTS="--entitlements ${ENTITLEMENTS_FILE}"
    echo " ** Entitlements: ${ENTITLEMENTS_FILE}"
  fi

  codesign --deep --force --verify --timestamp ${ADD_ENTITLEMENTS:+"$ADD_ENTITLEMENTS"} --options runtime -s "${SIGNING_ID}" "${TARGET_APP}"

  retVal=$?
  if [ $retVal -ne 0 ]; then
      echo "Error running codesign"
      exit
  fi
  
  echo "** Verifying: ${TARGET_APP}"
  codesign -dv --verbose "${TARGET_APP}"
}

function zipApplication()
{
  TARGET_APP_PATH="$(dirname "${TARGET_APP}")"
  BASE_APP="$(basename "${TARGET_APP}")"
  BASE_ZIP="$(basename "${ZIP_NAME}")"

  cd "${TARGET_APP_PATH}" || exit
  if [ -e "${BASE_APP}" ]; then
      rm -f "${BASE_ZIP}"
      # NOTE: cannot use zip! It causes notarization errors.
      ditto -c -k --sequesterRsrc --keepParent "${BASE_APP}" "${BASE_ZIP}"

      retVal=$?
      if [ $retVal -ne 0 ]; then
          echo "Error running ditto"
          exit
      fi
  fi
}

function notarizeTarget()
{
  TARGET="${1}"

  echo "** Notarizing: ${TARGET}"

  if [ ! -e "${TARGET}" ]; then
      echo "ERROR: Cannot find zip: ${TARGET}"
      exit
  fi

  xcrun notarytool submit "${TARGET}" --keychain-profile "${NOTARIZATION_KEYCHAIN}" --verbose --wait 

  retVal=$?
  if [ $retVal -ne 0 ]; then
      echo "Error running notarytool. Run the following to actually find out the error (NOTARIZE_ID comes from the failure output):"
      echo "xcrun notarytool log NOTARIZE_ID --keychain-profile \"notarytool\" error.json"
      exit
  fi
}

function stapleTarget()
{
  TARGET="${1}"

  echo "** Stapling: ${TARGET}"

  if [ ! -e "${TARGET}" ]; then
      echo "ERROR: Cannot find target: ${TARGET}"
      exit
  fi

  xcrun stapler staple "${TARGET}"

  retVal=$?
  if [ $retVal -ne 0 ]; then
      echo "Error running stapler"
      exit
  fi

  spctl -a -t exec -vvv "${TARGET}"
}

signApplication "${TARGET_APP}" "${SIGNING_ID}" ${ENTITLEMENTS_FILE:+"$ENTITLEMENTS_FILE"}
zipApplication
notarizeTarget "${ZIP_NAME}"
stapleTarget "${TARGET_APP}"

rm -f "${ZIP_NAME}"