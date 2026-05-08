import AppKit
import Foundation

let outputPath = "assets/sushma resume.pdf"
let pageWidth: CGFloat = 595.2
let pageHeight: CGFloat = 841.8
let margin: CGFloat = 46
let contentWidth = pageWidth - (margin * 2)

let data = NSMutableData()
var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
guard let consumer = CGDataConsumer(data: data),
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
  fatalError("Unable to create PDF context")
}

let black = NSColor(calibratedWhite: 0.05, alpha: 1)
let muted = NSColor(calibratedWhite: 0.25, alpha: 1)
let rule = NSColor(calibratedWhite: 0.15, alpha: 1)
let accent = NSColor(calibratedRed: 0.93, green: 0.66, blue: 0.0, alpha: 1)

func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
  return NSFont.systemFont(ofSize: size, weight: weight)
}

func attrs(size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = black, lineHeight: CGFloat? = nil) -> [NSAttributedString.Key: Any] {
  let paragraph = NSMutableParagraphStyle()
  paragraph.lineSpacing = 2
  if let lineHeight {
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight
  }
  return [
    .font: font(size, weight),
    .foregroundColor: color,
    .paragraphStyle: paragraph
  ]
}

func height(for text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
  let rect = NSString(string: text).boundingRect(
    with: CGSize(width: width, height: .greatestFiniteMagnitude),
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: attributes
  )
  return ceil(rect.height)
}

final class PDFWriter {
  let context: CGContext
  var y: CGFloat = 0
  var pageNumber = 0

  init(context: CGContext) {
    self.context = context
  }

  func newPage() {
    if pageNumber > 0 {
      context.restoreGState()
      context.endPDFPage()
    }

    context.beginPDFPage(nil)
    context.saveGState()
    context.translateBy(x: 0, y: pageHeight)
    context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    y = margin
    pageNumber += 1
  }

  func ensure(_ needed: CGFloat) {
    if y + needed > pageHeight - margin {
      newPage()
    }
  }

  func drawText(_ text: String, x: CGFloat = margin, width: CGFloat = contentWidth, attributes: [NSAttributedString.Key: Any], after: CGFloat = 0) {
    let h = height(for: text, width: width, attributes: attributes)
    ensure(h + after)
    NSString(string: text).draw(with: CGRect(x: x, y: y, width: width, height: h + 4), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
    y += h + after
  }

  func section(_ title: String) {
    ensure(34)
    y += 8
    context.setStrokeColor(rule.cgColor)
    context.setLineWidth(1)
    context.move(to: CGPoint(x: margin, y: y + 19))
    context.addLine(to: CGPoint(x: pageWidth - margin, y: y + 19))
    context.strokePath()
    drawText(title.uppercased(), attributes: attrs(size: 13, weight: .bold), after: 9)
  }

  func role(period: String, title: String, company: String, bullets: [String]) {
    let leftWidth: CGFloat = 120
    let gap: CGFloat = 18
    let rightX = margin + leftWidth + gap
    let rightWidth = contentWidth - leftWidth - gap
    let bulletText = bullets.map { "- \($0)" }.joined(separator: "\n")
    let titleAttrs = attrs(size: 11.5, weight: .bold)
    let companyAttrs = attrs(size: 10, weight: .bold, color: muted)
    let bulletAttrs = attrs(size: 9.7, color: black, lineHeight: 13)
    let needed = max(
      height(for: period, width: leftWidth, attributes: attrs(size: 9.8, weight: .bold)),
      height(for: title, width: rightWidth, attributes: titleAttrs)
        + height(for: company, width: rightWidth, attributes: companyAttrs)
        + height(for: bulletText, width: rightWidth, attributes: bulletAttrs)
        + 8
    )
    ensure(needed + 9)
    let startY = y
    NSString(string: period).draw(with: CGRect(x: margin, y: startY, width: leftWidth, height: needed), options: [.usesLineFragmentOrigin], attributes: attrs(size: 9.8, weight: .bold))
    NSString(string: title).draw(with: CGRect(x: rightX, y: startY, width: rightWidth, height: 18), options: [.usesLineFragmentOrigin], attributes: titleAttrs)
    NSString(string: company).draw(with: CGRect(x: rightX, y: startY + 17, width: rightWidth, height: 18), options: [.usesLineFragmentOrigin], attributes: companyAttrs)
    NSString(string: bulletText).draw(with: CGRect(x: rightX, y: startY + 34, width: rightWidth, height: needed), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: bulletAttrs)
    y = startY + needed + 9
  }
}

let pdf = PDFWriter(context: context)
pdf.newPage()

pdf.drawText("Sushma B M", attributes: attrs(size: 30, weight: .bold), after: 4)
pdf.drawText("System Application Engineer / Business Execution Consultant", attributes: attrs(size: 12, weight: .bold), after: 6)

let contact = "+91 9164139255  |  sushmabm.94@gmail.com  |  Bengaluru, India\nlinkedin.com/in/sushma-b-m-722b47188"
pdf.drawText(contact, attributes: attrs(size: 9.8, color: muted), after: 13)

context.setFillColor(accent.cgColor)
context.fill(CGRect(x: margin, y: pdf.y, width: 70, height: 4))
pdf.y += 18

pdf.section("Summary")
pdf.drawText(
  "Dedicated banking professional with 10+ years of continuous experience, currently serving as a System Application Engineer at Wells Fargo India Solutions. Transitioned from Business Execution Consultant in May 2026, with core responsibilities in line and queue monitoring, incident management, payments monitoring, risk management, and financial operations remaining central throughout.",
  attributes: attrs(size: 10.2, color: black, lineHeight: 14),
  after: 4
)

pdf.section("Work Experience")
pdf.role(
  period: "May 2026 - Present",
  title: "System Application Engineer",
  company: "Wells Fargo India Solutions Pvt Ltd - Hyderabad",
  bullets: [
    "Continue line and queue monitoring across FED/CHIPS, USD wire lines, and ACH channels, ensuring 22x5 payment processing continuity.",
    "Maintain incident management and escalation protocols to leadership contacts during critical issues.",
    "Provide system-level application oversight, monitoring infrastructure health and transmission stability.",
    "Support technical validations and release events as system application owner."
  ]
)
pdf.role(
  period: "Mar 2025 - Apr 2026",
  title: "Business Execution Consultant",
  company: "Wells Fargo India Solutions Pvt Ltd - Payments Command Center",
  bullets: [
    "Part of pilot batch Payments Command Center, building foundational processes from scratch.",
    "Provided centralized 22x5 payments analytics across FED/CHIPS clearing channels, USD wire lines and queues, and ACH channels.",
    "Monitored the firm's intraday liquidity position and CHIPS pre-funding in GMTS/EMTS.",
    "Created intakes and user stories while supporting business requirements and stakeholder communication."
  ]
)
pdf.role(
  period: "Jun 2023 - Mar 2025",
  title: "Business Execution Associate",
  company: "Wells Fargo India Solutions Pvt Ltd",
  bullets: [
    "Ensured end-to-end monitoring and preemptive controls to mitigate risk and improve payments execution.",
    "Established team structure, SOPs, procedures, logistics, access request support, and weekly metrics reporting.",
    "Supported testing, validations, implementation, and release events as required."
  ]
)
pdf.role(
  period: "May 2022 - Jun 2023",
  title: "Lead Operations Processor",
  company: "Wells Fargo India Solutions Pvt Ltd",
  bullets: [
    "Cross-trained in production support, including connections to FED and CHIPS systems.",
    "Monitored CHIPS pre-funding, oversaw CLS payments operations, produced weekly metrics, and supported onboarding."
  ]
)
pdf.role(
  period: "Jun 2015 - Apr 2022",
  title: "Control Room Specialist / Operations Analyst / Analyst",
  company: "JP Morgan Services India Pvt Ltd - Bengaluru",
  bullets: [
    "Monitored JPM infrastructure including systems, links, transmission networks, USD payments, and SEPA transactions.",
    "Initiated high-priority tickets when bank reputation or internal/external cutoffs were at risk.",
    "Monitored SWIFT messaging infrastructure and JPM connectivity via SBUS, SAG, AMH, and FING.",
    "Handled SWIFT message queries for Cash operations, assisted LOBs with NACK codes, and monitored posting applications."
  ]
)

pdf.section("Expertise")
pdf.drawText(
  "Payments Operations - Wires / ACH | Command Center Alert Management | Incident and Escalation Management | Liquidity Management | Business and Technology Collaboration | Agile Methodology and Scrum | Agile Certified Practitioner (PMI-ACP) | Intake Request and User Story Development | SWIFT Messaging Infrastructure | FED / CHIPS / CLS / SEPA Payments | Dashboard Analytics and Reporting | Risk Mitigation and Controls",
  attributes: attrs(size: 9.8, lineHeight: 13),
  after: 0
)

pdf.section("Key Projects")
pdf.drawText(
  "Payments Command Center Pilot Build: Established SOPs, logistics, and 22x5 analytics dashboards for FED/CHIPS, USD wire lines, and ACH channels.\n\nIntraday Liquidity Monitoring: Supported real-time liquidity oversight and CHIPS pre-funding monitoring through proactive escalation protocols.\n\nGlobal SWIFT Infrastructure Oversight: Managed SWIFT messaging infrastructure and connectivity tools across SBUS, SAG, AMH, and FING.",
  attributes: attrs(size: 9.8, lineHeight: 13),
  after: 0
)

pdf.section("Education")
pdf.drawText("Bachelor of Commerce - Bangalore University, MLAFGCW | June 2012 - March 2015", attributes: attrs(size: 10, lineHeight: 13), after: 0)

context.restoreGState()
context.endPDFPage()
context.closePDF()

try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
print("Generated \(outputPath) (\(data.length) bytes)")
