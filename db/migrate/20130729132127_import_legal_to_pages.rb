# encoding: utf-8
class ImportLegalToPages < ActiveRecord::Migration

  class Instance < ActiveRecord::Base
  end

  class Page < ActiveRecord::Base
  end

  def up
    content = <<-MARKDOWN
# Privacy Policy

Your privacy is important to Desks Near Me. This privacy policy ("Policy") applies to all Desks Near Me sites ("Sites"). This Policy explains how your personal information is collected, used, and disclosed by Desks Near Me.

Desks Near Me, Inc. complies with the U.S. – E.U. Safe Harbor framework and the U.S. - Swiss Safe Harbor framework as set forth by the U.S. Department of Commerce regarding the collection, use, and retention of personal data from European Union member countries and Switzerland. Desks Near Me, Inc. has certified that it adheres to the Safe Harbor Privacy Principles of notice, choice, onward transfer, security, data integrity, access, and enforcement.

## Personal Information Collected

We collect information from you in various ways when you use our Sites and Applications. We may collect personal information you directly provide on our Sites. In addition, we may collect personal information from you as a user of our Applications. Information we may collect includes name and email address, and phone number.

In addition, when you visit our Sites some information may be automatically collected. For example, it is standard for your Web browser to automatically send information to every Web site you visit including ours. That information includes your computer's Internet Protocol (IP) address, access times, browser type and language, and referring Web site addresses. We may also collect information about your computer's operating system and information about your usage and activity on our Sites. We use this information, which does not identify individual users, to analyze trends, to administer the site, to track users’ movements around the site and to gather demographic information about our user-base as a whole.

### Cookies

We may automatically collect certain information through the use of "cookies." Cookies are small data files that are stored on your hard drive by a Web site. Among other things, the use of cookies helps us to improve our Sites and your experience. We use cookies to see which areas and features are most popular, to count the number of computers accessing our Sites, to personalize your experience, and to remember your preferences.

We link the information we store in cookies to any personally identifiable information you submit while on our site. If your browser is set not to accept cookies or if you reject a cookie, you may not be able to access certain features or services of our Sites. The use of cookies by our service providers is not covered by our privacy statement. We do not have access or control over these cookies. Our service providers use session ID cookies to collect data in order to enable us to provide a better user experience.

## Use Of Personal Information We Collect

We use your personal information to provide you with services, to operate and improve our Sites and Applications, to send you messages, and for other purposes described in this Policy or disclosed to you on our Sites or in connection with our services. For example, we may use the information we collect from you on our Sites and Applications:

* to register for an account with us;
* to apply to become a partner;
* to personalize and improve your experience on our Sites and with our Applications;
* to respond to comments and questions and provide customer service;
* to deliver service messages and other services and content you request and to send information related to accounts and services, including confirmations, invoices, technical notices, updates, security alerts, and support and administrative messages;
* to send you information about new promotions, products, and services offered by Desks Near Me and our selected partners; and
* to conduct an aggregated analysis of the performance of our site.

Desks Near Me may store and process personal information in the United States and other countries.

## Sharing Of Personal Information

We use third parties such as a credit card processing company to bill you for services, an email service provider to send out emails on our behalf, a company to provide our forums and an employment resources company to process your job applications. When you sign up for our services, we will share the personal information you provide only as necessary for the third party to provide that service.

Desks Near Me will co-own data that may include your name, email address, phone number and birth date. We may use aggregate data collected for internal analysis purposes.

We do not share your personal information with third parties other than as described above and as follows:

* with third party vendors, consultants and other service providers ("Service Providers") who are working on our behalf and need access to your information to carry out their work for us;
* to (a) comply with laws or respond to lawful requests and legal process, (b) to protect the rights and property of Desks Near Me, our agents, members, and others including to enforce our agreements, policies and terms of use, or (c) in the good faith belief that disclosure is needed to respond to an emergency or protect the personal safety of any person; and
* in connection with any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company. In any such event, we will provide notice if your data is transferred and becomes subject to a different privacy policy.

## SECURITY OF YOUR PERSONAL INFORMATION

The security of your personal information is important to us. When you enter sensitive information (such as credit card number) on our registration or order forms, we encrypt that information using secure socket layer technology (SSL).

Desks Near Me takes reasonable security measures to protect your personal information to prevent loss, misuse, unauthorized access, disclosure, alteration, and destruction. Please be aware, however, that despite our efforts, no security measures are impenetrable.

If you use a password on our Site, you are responsible for keeping it confidential. Do not share it with any other person. If you believe your password has been misused, please advise us immediately.

## Choices About Use Of Your Information

You may "opt-out" of receiving promotional emails from Desks Near Me by following the instructions in those emails. You may also send requests relating to promotional messages and your permission for sharing information with third parties for their marketing purposes by Opt-out requests will not apply to transactional service messages, including messages about your current Desks Near Me account and services.

## Updating And Accessing Your Personal Information

If your personal information changes, we invite you to correct or update your information as soon as possible. We will retain your information for as long as your account is active or as needed to provide you services. If you wish to cancel your account, request that we no longer use your information to provide you services or delete your personal information, please contact us at support@desksnear.me.  We will respond to your request to have your personal information deleted within 30 days. We will retain and use your information as necessary to comply with our legal obligations, resolve disputes, and enforce our agreements.

## Links To Other Sites

Our Site includes links to other Web sites whose privacy practices may differ from those of Desks Near Me. If you submit personal information to any of those sites, your information is governed by their privacy statements. We encourage you to carefully read the privacy statement of any Web site you visit.

## Testimonials

We post customer testimonials on our web site which may contain personally identifiable information. We do obtain the customer's consent via email prior to posting the testimonial to post their name along with their testimonial. If you wish to request that your testimonial be removed you may do so by emailing us at support@desksnear.me

## Public Forums

Our Web site offers publicly accessible blogs or community forums. You should be aware that any information you provide in these areas may be read, collected, and used by others who access them. To request removal of your personal information from our blog or community forum, contact us support@desksnear.me In some cases, we may not be able to remove your personal information, in which case we will let you know if we are unable to do so and why.

## Social Media Features

Our Web site includes Social Media Features, such as the Facebook Like button. These Features may collect your IP address, which page you are visiting on our site, and may set a cookie to enable the Feature to function properly. Social Media Features are either hosted by a third party or hosted directly on our Site. Your interactions with these Features are governed by the privacy policy of the company providing it.

## Changes To This Policy

Desks Near Me may change this Policy from time to time. If we make any changes to this Policy, we will change the "Last Updated" date above. If there are material changes to this policy, we will notify you by email (sent to the e-mail address specified in your account). We encourage you to review this Policy whenever you visit our Sites or use our Applications to understand how your personal information is used.

## Questions About This Policy

If you have any questions about this Policy, please contact us at support@desksnear.me or Desks Near Me, Inc. 54 Pier  Suite #209, San Francisco, CA 94158.

# DESKS NEAR ME Terms of use

Welcome to www.desksnear.me.   Desks Near Me Inc. (“DNM,” “we” or “us”) provides this website (the "Site") to you subject to these terms and conditions of use (“Terms” or “Agreement”).  The Site is comprised of various web pages operated by Desks Near Me.  By accessing, using, or by merely browsing the Site you agree to be legally bound by these Terms and all terms, policies and guidelines incorporated by reference in these Terms.  If you do not agree with these Terms in their entirety, you may not use the Site.  Please read these terms carefully, and keep a copy of them for your reference.  The purpose of this website is to provide information regarding services available through DNM.

In these Terms, our customers, hosts, vendors, partners, casual browsers of the Site and any person who gains access to this Site are referred to as “Users.”  This Site is not intended to be used by children. DNM does not knowingly collect, either online or offline, personal information from persons under the age of thirteen (13).  If you are under 18, you may use the Site only with permission of a parent or guardian.  DNM reserves the right to change or modify any of the terms and conditions contained in these Terms, or any policy or guideline of the Site, at any time and in its sole discretion.  The most current version of the Terms will supersede all previous versions.  Unless otherwise specified, any changes or modifications will be effective immediately upon posting of the revisions on the Site, and your continued use of the Site after such time will constitute your acceptance of such changes or modifications. You should from time to time review the Terms and any policies and documents incorporated in them to understand the terms and conditions that apply to your use of the Site.  The Terms will always show the ‘last updated’ date at the top.  If you do not agree to any amended Terms, you must stop using the Site.  If you have any questions about the Terms, please email us at support@desksnear.me.

## 1. Privacy Policy; Electronic Communications

Your use of the Site is subject to DNM's Privacy Policy.  Please refer to the Desks Near Mw Privacy Policy, available on our site for information on how DNM collects, uses, and discloses personally identifiable information from its users.  By using the Site you agree to our use, collection and disclosure of personally identifiable information in accordance with our Privacy Policy.

Visiting DNM or sending emails to DNM constitutes electronic communications. You consent to receive electronic communications and you agree that all agreements, notices, disclosures and other communications that we provide to you electronically, via email and on the Site, satisfy any legal requirement that such communications be in writing.

## 2. Your Account

If you use this Site, you are responsible for maintaining the confidentiality of your account and password and for restricting access to your computer, and you agree to accept responsibility for all activities that occur under your account or password. You may not assign or otherwise transfer your account to any other person or entity.  You acknowledge that DNM is not responsible for third party access to your account that results from theft or misappropriation of your account.  DNM and its associates, affiliates and partners reserve the right to refuse or cancel service, terminate accounts, or remove or edit content in our sole discretion.

## 3. Fees; Charges; Cancellations; Refund Policy

Fees and any other charges, cancellations and refunds are made in accordance with the DNM Terms of Service.

## 4. Ownership, Copyright and Trademarks

In these Terms the content on the Site, including all information, data, logos, marks, designs, graphics, pictures, sound files, other files, and their selection and arrangement, is called “Content.”  Content provided by Users is called “User Content.”  User Content remains the property of the User.  DNM's rights to User Content are limited to the limited licenses granted in Section 11 of these Terms.  Other than User Content, the Site, all Content and all software available on the Site or used to create and operate the Site is the property of Desks Near Me or its licensors, and is protected by United States and international copyright and intellectual property laws, and all rights to the Site, the Content and software are expressly reserved.  All trademarks, registered trademarks, product names and company names or logos mentioned in the Site are the property of their respective owners.  Reference to any products, services, processes or other information, by trade name, trademark, manufacturer, supplier or otherwise does not constitute or imply endorsement, sponsorship or recommendation thereof by DNM.  DNM collects certain information and data during the normal operation of the Site. The information and data collected through the operation of the Site is the property of Desks Near Me unless Desks Near Me has agreed to collect information and data on behalf of a User or customer.  Any agreement by Desks Near Me to collect information and data on behalf of a User or customer must be memorialized in a Services Agreement.  In the event of conflict or inconsistency between any of the provisions of this Agreement and the Services Agreement, the Services Agreement shall be given precedence.  Your User Content is your responsibility.  Desks Near Me has no responsibility or liability for your User Content, or for any loss or damage your User Content may cause to you or other people.  Although Desks Near Me has no obligation to do so, Desks Near Me has the absolute discretion to remove any User Content posted or stored on the Site, and Desks Near Me may do this at any time and for any reason.  Desks Near Me is solely responsible for maintaining copies of and replacing any User Content you post or store on the Site.

## 5. Desks Near Me Limited License of Content to You

Desks Near Me grants you a limited, revocable, non-exclusive, license to access and use the Site and to view, copy and print the portions of the Content available to you on the Site strictly in accordance with these Terms.  Such license is specifically conditioned upon the following: (i) you warrant to Desks Near Me that you will not use the Site for any purpose that is unlawful or prohibited by these Terms; (ii) you may only view, copy and print such portions of the Content for your own use; (iii) you may not modify, publish, transmit, reverse engineer, participate in the transfer or sale, or otherwise make derivative works of the Site or the Content, or reproduce, distribute, exploit or display the Site or any Content (except for page caching) except as expressly permitted in these Terms; (iv) you may not remove or modify any copyright, trademark, or other proprietary notices that have been placed in the Content; (v) you may not use any data mining, robots or similar data gathering or extraction methods; (vi) you may not use the Site in any manner which could damage, disable, overburden, or impair the Site or interfere with any other party's use and enjoyment of the Site; and (vii) you may not use the Site or the Content other than for its intended purpose.  Except as expressly permitted above, any use of any portion of the Content without the prior written permission of its owner is strictly prohibited and will terminate the license granted in this Section, this Agreement and your account with us.  Any such unauthorized use may also violate applicable laws, including without limitation copyright and trademark laws.  All content included as part of the Service, such as text, graphics, logos, images, as well as the compilation thereof, and any software used on the Site, is the property of Desks Near Me or its suppliers or partners and protected by copyright and other laws that protect intellectual property and proprietary rights. You agree to observe and abide by all copyright and other proprietary notices, legends or other restrictions contained in any such content and will not make any changes thereto.  Your use of the Site does not entitle you to make any unauthorized use of any protected content, and in particular you will not delete or alter any proprietary rights or attribution notices in any Content.  You will use protected Content solely for your personal use, and will make no other use of the Content without the express written permission of Desks Near Me and the copyright owner.  You agree that you do not acquire any ownership rights in any protected Content.  Unless explicitly stated herein, nothing in these Terms may be construed as conferring any license, express or implied, to intellectual property rights, whether by estoppel, implication or otherwise.  The license in this Section is revocable by Desks Near Me at any time.  You represent and warrant that your use of the Site and the Content will be consistent with this license and will not infringe or violate the rights of any other party or breach any contract or legal duty to any other parties, or violate any applicable law.  To request permission for uses of Content not included in this license, you may contact Desks Near Me at the address identified at the bottom of these Terms.

## 6. Providing a Reliable and Secure Service

Desks Near Me takes security seriously.  Desks Near Me strives to maintain a reliable and secure environment for your data.  However, no system is perfectly secure or reliable, the Internet is an inherently insecure medium, and the reliability of hosting services, Internet intermediaries, your Internet service provider, and other service providers cannot be assured.  When you use the Site, you accept these risks, and the responsibility for choosing to use a technology that does not provide perfect security or reliability.

## 7. Links to Third Party Sites

The Site may contain links to other third-party websites (“Third-Party Sites”) and third-party content (“Third-Party Content”).  The Third-Party Sites are not under the control of Desks Near Me and Desks Near Me is not responsible for the contents of any Third-Party Site, including without limitation any link contained in a Third-Party Site, or any changes or updates to a Third-Party Site.  Desks Near Me does not make any claims or representations to any Third-Party Sites.  Desks Near Me is providing these links to you only as a convenience, and the inclusion of any link does not imply endorsement, adoption or sponsorship of, or affiliation with Desks Near Me of such Third-Party Site or Third-Party Content or any association with its operators.  When you leave the Site, Desks Near Me’s Terms and policies are no longer applicable.  You should review applicable terms and policies, including privacy and data gathering practices, of any Third-Party Site, and should make whatever investigation you feel necessary or appropriate before proceeding with any transaction with any third-party.

Certain services made available via the Site are delivered by third party sites and organizations. By using any product, service or functionality originating from the www.birddogjet.com domain, you hereby acknowledge and consent that Desks Near Me may share such information and data with any third party with whom Desks Near Me has a contractual relationship to provide the requested product, service or functionality on behalf of the Site’s Users and customers.

## 8.  Third Party Accounts

You will be able to connect your Desks Near Me account to third party accounts.  By connecting your Desks Near Me account to your third party account, you acknowledge and agree that you are consenting to the continuous release of information about you to others (in accordance with your privacy settings on those third party sites). If you do not want information about you to be shared in this manner, do not use this feature.

## 9.  International Users

The Service is controlled, operated and administered by Desks Near Me from our offices within the USA.  If you access the Service from a location outside the USA, you are responsible for compliance with all local laws.  You agree that you will not use the Desks Near Me Content accessed through the Site in any country or in any manner prohibited by any applicable laws, restrictions or regulations.

10. Warranty Disclaimer

THE INFORMATION, SOFTWARE, PRODUCTS, AND SERVICES INCLUDED IN OR AVAILABLE THROUGH THE SITE MAY INCLUDE INACCURACIES OR TYPOGRAPHICAL ERRORS.  CHANGES ARE PERIODICALLY ADDED TO THE INFORMATION HEREIN.  Desks Near Me AND/OR ITS SUPPLIERS, VENDORS AND/OR PARTNERS MAY MAKE IMPROVEMENTS AND/OR CHANGES IN THE SITE AT ANY TIME.

THE SITE, THE CONTENT AND THE SERVICES PROVIDED BY THE SITE ARE PROVIDED TO YOU ON AN “AS IS” BASIS WITHOUT WARRANTIES FROM Desks Near Me OF ANY KIND, EITHER EXPRESS OR IMPLIED.  Desks Near Me EXPRESSLY DISCLAIMS ALL OTHER WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT.  Desks Near Me DOES NOT REPRESENT OR WARRANT THAT CONTENT IS ACCURATE, COMPLETE, RELIABLE, CURRENT OR ERROR-FREE, AND EXPRESSLY DISCLAIMS ANY WARRANTY OR REPRESENTATION AS TO THE ACCURACY OR PROPRIETARY CHARACTER OF THE SITE, THE CONTENT OR ANY PORTION THEREOF.  While Desks Near Me attempts to make your access to and use of the Site safe, Desks Near Me does not represent or warrant that the Site or any Content are free of viruses or other harmful components.

## 11. Indemnification

You agree to indemnify, defend and hold harmless Desks Near Me, its officers, directors, employees, agents and third parties, for any losses, costs, liabilities and expenses (including reasonable attorneys' fees) relating to or arising out of your use of or inability to use the Site or services, any user postings made by you, your violation of any terms of this Agreement or your violation of any rights of a third party, or your violation of any applicable laws, rules or regulations.  Desks Near Me reserves the right, at its own cost, to assume the exclusive defense and control of any matter otherwise subject to indemnification by you, in which event you will fully cooperate with Desks Near Me in asserting any available defenses.

## 12.  Limitation of Liability; Indemnity

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, YOU WAIVE AND SHALL NOT ASSERT ANY CLAIMS OR ALLEGATIONS OF ANY NATURE WHATSOEVER AGAINST Desks Near Me, ITS AFFILIATES OR SUBSIDIARIES, THEIR CONTRACTORS, ADVERTISERS, VENDORS OR OTHER PARTNERS, ANY OF THEIR SUCCESSORS OR ASSIGNS, OR ANY OF THEIR RESPECTIVE OFFICERS, DIRECTORS, AGENTS OR EMPLOYEES (COLLECTIVELY, THE “RELEASED PARTIES”) ARISING OUT OF OR IN ANY WAY RELATING TO YOUR USE OR PERFORMANCE OF THE SITE OR THE CONTENT, INCLUDING, WITHOUT LIMITATION, ANY CLAIMS OR ALLEGATIONS RELATING TO THE ALLEGED INFRINGEMENT OF PROPRIETARY RIGHTS, ALLEGED INACCURACY OF CONTENT, OR ALLEGATIONS THAT ANY RELEASED PARTY HAS OR SHOULD INDEMNIFY, DEFEND OR HOLD HARMLESS YOU OR ANY THIRD-PARTY FROM ANY CLAIM OR ALLEGATION ARISING FROM YOUR USE OR OTHER EXPLOITATION OF THE SITE. <strong>YOU USE THE SITE AT YOUR OWN RISK</strong>. Without limitation of the foregoing, to the maximum extent permitted by law, neither Desks Near Me nor any other Released Party shall be liable for any direct, special, indirect or consequential damages, or any other damages of any kind, including but not limited to loss of use, loss of profits or loss of data, whether in an action in contract, tort (including but not limited to negligence) or otherwise, arising out of or in any way connected with the use of the Site or the Content, including without limitation any damages caused by or resulting from your reliance on the Site or other information obtained from Desks Near Me or any other Released Party or accessible via the Site, or that result from mistakes, errors, omissions, interruptions, deletion of files or email, defects, viruses, delays in operation or transmission or any failure of performance, whether or not resulting from acts of god, communications failure, theft, destruction or unauthorized access to Desks Near Me or any other Released Party's records, programs or Services.  In no event shall the aggregate liability of Desks Near Me, whether in contract, warranty, tort (including negligence, whether active, passive or imputed), product liability, strict liability or other theory, arising out of or relating to the use of the Site, even if Desks Near Me or any of its Suppliers or Partners has been advised of the possibility of damages, exceed any compensation paid by you for access to or use of the Site during the three (3) months prior to the date of any claim.  Nothing in these Terms shall limit Desks Near Me’s liability in any claim for fraud or fraudulent misrepresentation.  Because some states/jurisdictions do not allow the exclusion or limitation of liability for consequential or incidental damages, the above limitation may not apply to you.  If you are dissatisfied with any portion of the Site, or with any of these Terms, your sole and exclusive remedy is to discontinue using the Site

## 13. Communications

Notices will be posted on the Site in the area of the Site suitable to the notice. It is your responsibility to periodically review the Site for notices. Subject to the Privacy Policy, if you send to Desks Near Me, or post on the Site in any public area, any information, idea, invention, concept, technique or know-how (“User Submissions”), for any purpose, including the development, manufacturing and/or marketing of products or services incorporating such information, you acknowledge that Desks Near Me can use the User Submissions without acknowledgement or compensation to you, and you waive any claim of ownership or compensation or other rights you may have in relation to the User Submissions. Desks Near Me actively reviews User Submissions.  If you wish to preserve any interest you might have in your User Submissions, you should not post them to the Site or send them to us.

## 14. Applicable Law and Venue

PLEASE NOTE: This Agreement requires the use of arbitration on an individual basis to resolve disputes, rather than jury trials or class actions, and also limits the remedies available to you in the event of a dispute.  The Site is controlled by Desks Near Me Inc. and operated from its offices in San Francisco, California.  You and Desks Near Me both benefit from establishing a predictable legal environment in regard to the Site.  Therefore, you and Desks Near Me explicitly agree that all disputes, claims or other matters arising from or relating to your use of the Site will be governed by the laws of the State of California and the federal laws applicable therein.   Except where prohibited by applicable law, any claim, dispute or controversy arising out of or relating to these Terms; (b) the Site or Content; (c) oral or written statements, advertisements or promotions relating to these Terms or to the Site; or (d) the relationships that result from these Terms or the Site or Content (collectively, a “Claim”) will be referred to and determined by a sole arbitrator (to the exclusion of the courts).  This agreement to arbitrate is intended to be broadly interpreted.  It includes, but is not limited to: (1) claims arising out of or relating to any aspect of the relationship between us, whether based in contract, tort, statute, fraud, misrepresentation or any other legal theory; (2) claims that arose before this or any prior Agreement; (3) claims that are currently the subject of purported class action litigation in which you are not a member of a certified class; and (4) claims that may arise after the termination of this Agreement.  You consent to the personal jurisdiction of such courts over you, stipulate to the fairness and convenience of proceeding in such courts, and covenant not to assert any objection to proceeding in such courts.  If you choose to access the Site from locations other than California, you will be responsible for compliance with all local laws of such other jurisdiction and you agree to indemnify Desks Near Me and the other Released Parties for your failure to comply with any such laws

## 15. Termination/Modification of License and Site Offerings

Notwithstanding any provision of these Terms, Desks Near Me reserves the right, without notice and in its sole discretion, without any notice or liability to you, to (a) terminate your license to use the Site, or any portion thereof; (b) block or prevent your future access to and use of all or any portion of the Site or Content; (c) change, suspend or discontinue any aspect of the Site or Content; and (d) impose limits on the Site or Content

## 16. Miscellaneous

You agree that no joint venture, partnership, employment, or agency relationship exists between you and Desks Near Me as a result of this Agreement or use of the Site.  Desks Near Me’s performance of this Agreement is subject to existing laws and legal process, and nothing contained in this Agreement is in derogation of Desks Near Me’s right to comply with governmental, court and law enforcement requests or requirements relating to your use of the Site or information provided to or gathered by Desks Near Me with respect to such use.  If any part of this Agreement is determined to be invalid or unenforceable pursuant to applicable law including, but not limited to, the warranty disclaimers and liability limitations set forth above, then the invalid or unenforceable provision will be deemed superseded by a valid, enforceable provision that most closely matches the intent of the original provision and the remainder of the agreement shall continue in effect.  If a court of competent jurisdiction determines that any provision of these Terms is invalid, unlawful, void or unenforceable, that provision shall be modified or severed to the maximum extent permitted by law; however, any and all other provisions shall remain valid and be given full force and effect in a valid and enforceable manner to accomplish the purposes of these Terms.  Desks Near Me may assign any or all of its rights hereunder to any party without your consent.  You are not permitted to assign any of your rights or obligations hereunder without the prior written consent of Desks Near Me, and any such attempted assignment will be void and unenforceable.  These Terms constitute the entire agreement between you and Desks Near Me regarding your use of the Site, and supersede all prior or contemporaneous communications whether electronic, oral or written between you and Desks Near Me regarding your use of the Site.  The section titles in these Terms are for convenience only and have no legal or contractual effect.  A printed version of this Agreement and of any notice given in electronic form shall be admissible in judicial or administrative proceedings based upon or relating to this agreement to the same extent and subject to the same conditions as other business documents and records originally generated and maintained in printed form.  It is the express wish of the parties that this Agreement and all related documents be written in English.

## 17. Questions and Comments

If you have any questions regarding these Terms or your use of the Site, please contact us here: Desks Near Me Inc., support@desksnear.me
    MARKDOWN

    instance = Instance.where(name: 'DesksNearMe').first

    Page.create(instance_id: instance.id,
                content: content,
                path: 'legal')
  end

  def down
    instance = Instance.where(name: 'DesksNearMe').first
    Page.where(path: 'legal', instance_id: instance.id).destroy_all if instance
  end
end