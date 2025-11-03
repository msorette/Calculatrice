#!/usr/bin/bash

#
# Script to upload test results to Codebeamer
# Usage: ./upload-to-codebeamer.sh <USER> <PASS> <TEST_CASE_TRACKER_ID> <TEST_RUN_TRACKER_ID>
#

#
# Define a simple logging function
#
log() {
    ts="$(date --iso-8601='seconds')"
    echo -e "${ts} : $1" | tee -a ${LOG_FILENAME}
}

# Configuration
LOG_FILENAME="${GITHUB_WORKSPACE:-./target}/upload.log"
CB_BASE_URL="https://pp-2510240748rl.portal.ptc.io:9443/cb"
URL="${CB_BASE_URL}/rest/xunitresults/"

USER=$1
PASS=$2
TEST_CASE_TRACKER_ID=$3
TEST_RUN_TRACKER_ID=$4

# Optional params (can be set via environment variables or left empty)
TEST_CONFIG_ID="${TEST_CONFIG_ID:-}"
PARENT_TEST_CASE_ID="${PARENT_TEST_CASE_ID:-}"
RELEASE_ID="${RELEASE_ID:-}"
BUILD_ID="${BUILD_IDENTIFIER:-${GITHUB_RUN_NUMBER:-}}"
# Use PACKAGE_PREFIX from environment without default value
PACKAGE_PREFIX="${PACKAGE_PREFIX}"

# Prepare the test results file
WORKSPACE="${GITHUB_WORKSPACE:-.}"
REPORTS_DIR="${WORKSPACE}/target/surefire-reports"
ZIP_FILE="${WORKSPACE}/target/test_results.zip"

log "=== Starting Codebeamer Upload ==="
log "CB URL: ${URL}"
log "CB Username: ${USER}"
log "Test Case Tracker ID: ${TEST_CASE_TRACKER_ID}"
log "Test Run Tracker ID: ${TEST_RUN_TRACKER_ID}"
log "Build ID: ${BUILD_ID}"
log "Package Prefix: ${PACKAGE_PREFIX}"

# Check if test reports exist
if [ ! -d "${REPORTS_DIR}" ]; then
    log "ERROR: Test reports directory not found: ${REPORTS_DIR}"
    exit 1
fi

# Create zip file with test results
log "Creating zip file from test results..."
cd "${WORKSPACE}/target"
if [ -f "${ZIP_FILE}" ]; then
    rm "${ZIP_FILE}"
fi

# List XML files to be zipped
log "XML files found:"
ls -lh surefire-reports/TEST-*.xml | tee -a ${LOG_FILENAME}

# Zip all XML test result files
zip -j "${ZIP_FILE}" surefire-reports/TEST-*.xml >> ${LOG_FILENAME} 2>&1

if [ ! -f "${ZIP_FILE}" ]; then
    log "ERROR: Failed to create zip file"
    exit 1
fi

log "Zip file created: ${ZIP_FILE}"
log "Zip file size: $(ls -lh ${ZIP_FILE} | awk '{print $5}')"

# Display contents of the zip file
log "Zip file contents:"
unzip -l "${ZIP_FILE}" | tee -a ${LOG_FILENAME}

# Extract and display one XML file content for verification
log ""
log "=== Sample XML content (first 100 lines) ==="
unzip -p "${ZIP_FILE}" | head -100 | tee -a ${LOG_FILENAME}
log "=== End of sample XML ==="
log ""

# Build configuration JSON
CFG="{\"testConfigurationId\":\"$TEST_CONFIG_ID\",\"testCaseTrackerId\":\"$TEST_CASE_TRACKER_ID\",\"testCaseId\":\"$PARENT_TEST_CASE_ID\",\"releaseId\":\"$RELEASE_ID\",\"testRunTrackerId\":\"$TEST_RUN_TRACKER_ID\",\"buildIdentifier\":\"$BUILD_ID\",\"defaultPackagePrefix\":\"$PACKAGE_PREFIX\"}"

log "=== Request Details ==="
log "Endpoint URL: ${URL}"
log "HTTP Method: POST"
log "Authentication: Basic Auth (username: ${USER})"
log "Configuration JSON: ${CFG}"
log ""
log "Formatted Configuration:"
echo "${CFG}" | python3 -m json.tool 2>/dev/null || echo "${CFG}" | tee -a ${LOG_FILENAME}
log ""
log "File being uploaded: ${ZIP_FILE}"
log "=== End Request Details ==="
log ""

# Upload to Codebeamer with verbose output
log "Uploading test results to Codebeamer..."
HTTP_CODE=$(curl -w "%{http_code}" -o "${LOG_FILENAME}.response" \
    --verbose \
    --location --request POST "${URL}" \
    -u "${USER}:${PASS}" \
    --form "configuration=${CFG}" \
    --form "file=@${ZIP_FILE}" \
    2>&1 | tee -a ${LOG_FILENAME} | tail -1)

log ""
log "=== Response Details ==="
log "HTTP Response Code: ${HTTP_CODE}"
log ""

if [ -f "${LOG_FILENAME}.response" ]; then
    log "Response body:"
    cat "${LOG_FILENAME}.response" | tee -a ${LOG_FILENAME}
    echo "" >> ${LOG_FILENAME}
fi
log "=== End Response Details ==="
log ""

# Check if upload was successful
if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then
    log "SUCCESS: Test results uploaded successfully to Codebeamer!"
    exit 0
else
    log "ERROR: Failed to upload test results. HTTP code: ${HTTP_CODE}"
    exit 1
fi
