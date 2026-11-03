/*
 * INT-02: Build S/4HANA employee payload from SuccessFactors EmpJob OData response.
 * Alpine Beverage Group (fictional portfolio case study).
 */
import com.sap.gateway.ip.core.customdev.util.Message
import groovy.json.JsonOutput

/* Value mapping VM_EMPCLASS (see docs/03-field-mapping.md) */
@groovy.transform.Field
final Map EMPCLASS_MAP = ['1': '1', '2': '2', '3': '3', '4': '9']

def Message processData(Message message) {
    def body = message.getBody(String)
    def xml = new XmlSlurper().parseText(body)

    def employees = []
    def errors = []

    xml.EmpJob.each { job ->
        def personId = job.employmentNav.EmpEmployment.personNav.PerPerson.personIdExternal.text()
        def personal = job.employmentNav.EmpEmployment.personNav.PerPerson.personalInfoNav.PerPersonal

        if (!(personId ==~ /\d{1,8}/)) {
            errors << "Invalid personIdExternal: ${personId}"
            return
        }

        employees << [
            pernr    : personId.padLeft(8, '0'),
            firstName: personal.firstName.text(),
            lastName : personal.lastName.text(),
            begda    : toAbapDate(job.startDate.text()),
            bukrs    : job.company.text(),
            kostl    : job.costCenter.text().padLeft(10, '0'),
            stell    : job.jobCode.text(),
            persg    : EMPCLASS_MAP.get(job.employeeClass.text(), '9')
        ]
    }

    if (errors) {
        message.setProperty('MAPPING_ERRORS', errors.join('; '))
    }
    message.setProperty('EMPLOYEE_COUNT', employees.size().toString())
    message.setBody(JsonOutput.toJson([employees: employees]))
    message.setHeader('Content-Type', 'application/json')
    return message
}

/* SuccessFactors returns dates as ISO (2026-03-01T00:00:00.000) in XML. */
static String toAbapDate(String isoDate) {
    if (!isoDate) return '00000000'
    return isoDate.substring(0, 10).replace('-', '')
}
