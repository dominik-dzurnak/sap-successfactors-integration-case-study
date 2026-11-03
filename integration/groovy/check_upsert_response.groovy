/*
 * INT-01: Check SuccessFactors upsert response and fail the message if any record failed.
 * The upsert API returns HTTP 200 even when single records fail, so status must be checked per record.
 */
import com.sap.gateway.ip.core.customdev.util.Message
import groovy.json.JsonSlurper

def Message processData(Message message) {
    def response = new JsonSlurper().parseText(message.getBody(String))
    def results = response?.d ?: []

    def failed = results.findAll { it.status != 'OK' }
    message.setProperty('UPSERT_OK', (results.size() - failed.size()).toString())
    message.setProperty('UPSERT_FAILED', failed.size().toString())

    if (failed) {
        def details = failed.collect { "${it.key}: ${it.message}" }.join('; ')
        throw new IllegalStateException("FOCostCenter upsert failed for ${failed.size()} record(s): ${details}")
    }
    return message
}
