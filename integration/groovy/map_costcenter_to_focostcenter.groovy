/*
 * INT-01: Map S/4HANA cost centers (API_COSTCENTER_SRV) to SuccessFactors FOCostCenter.
 * Alpine Beverage Group (fictional portfolio case study).
 */
import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.MarkupBuilder
import java.time.LocalDate

def Message processData(Message message) {
    def body = message.getBody(String)
    def source = new XmlSlurper().parseText(body)
    def today = LocalDate.now().toString()

    def writer = new StringWriter()
    def xml = new MarkupBuilder(writer)

    xml.FOCostCenter {
        source.'**'.findAll { it.name() == 'A_CostCenterType' }.each { cc ->
            def validTo = cc.ValidityEndDate.text().take(10)
            FOCostCenter {
                externalCode(cc.CostCenter.text().replaceFirst(/^0+(?!$)/, ''))
                name(cc.CostCenterName.text())
                startDate(cc.ValidityStartDate.text().take(10))
                cust_CompanyCode(cc.CompanyCode.text())
                status(validTo >= today ? 'A' : 'I')
            }
        }
    }

    message.setBody(writer.toString())
    return message
}
