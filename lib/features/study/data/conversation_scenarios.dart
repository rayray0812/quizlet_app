import 'package:recall_app/services/gemini_service.dart';

/// Pre-built conversation scenarios for the scenario picker.
/// Each scenario has a stable `id` that must never change — title/text may be
/// localized or renamed freely without breaking stored references.
const List<ConversationScenario> kConversationScenarios = [
  ConversationScenario(
    id: 'pharmacy_pickup',
    title: 'Pharmacy Pickup',
    titleZh: '\u85E5\u5C40\u9818\u85E5',
    setting:
        'You are at a neighborhood pharmacy to pick up medicine before it closes in 20 minutes.',
    settingZh:
        '\u4F60\u5728\u793E\u5340\u85E5\u5C40\u9818\u85E5\uFF0C\u8DDD\u96E2\u6253\u70CA\u53EA\u522920\u5206\u9418\u3002',
    aiRole: 'Pharmacist',
    aiRoleZh: '\u85E5\u5E2B',
    userRole: 'Customer',
    userRoleZh: '\u9867\u5BA2',
    stages: [
      'State what you need to pick up',
      'Confirm your name and prescription details',
      'Ask dosage and timing',
      'Check side effects and precautions',
      'Confirm payment and leave',
    ],
    stagesZh: [
      '\u8AAA\u660E\u4F60\u8981\u9818\u7684\u85E5',
      '\u78BA\u8A8D\u59D3\u540D\u8207\u8655\u65B9\u8CC7\u8A0A',
      '\u8A62\u554F\u5291\u91CF\u8207\u670D\u7528\u6642\u9593',
      '\u78BA\u8A8D\u526F\u4F5C\u7528\u8207\u6CE8\u610F\u4E8B\u9805',
      '\u78BA\u8A8D\u4ED8\u6B3E\u5F8C\u96E2\u958B',
    ],
  ),
  ConversationScenario(
    id: 'train_ticket_change',
    title: 'Train Ticket Change',
    titleZh: '\u6539\u9AD8\u9435\u7968',
    setting:
        'You need to change your train ticket because your meeting was moved earlier.',
    settingZh:
        '\u4F60\u8981\u6539\u9AD8\u9435\u7968\uFF0C\u56E0\u70BA\u6703\u8B70\u63D0\u524D\u4E86\u3002',
    aiRole: 'Ticket Staff',
    aiRoleZh: '\u552E\u7968\u4EBA\u54E1',
    userRole: 'Passenger',
    userRoleZh: '\u4E58\u5BA2',
    stages: [
      'Explain why you need a ticket change',
      'Ask for an earlier departure',
      'Confirm seat availability',
      'Check fare difference and policy',
      'Complete payment and confirm platform',
    ],
    stagesZh: [
      '\u8AAA\u660E\u8981\u6539\u7968\u7684\u539F\u56E0',
      '\u8A62\u554F\u66F4\u65E9\u73ED\u6B21',
      '\u78BA\u8A8D\u5EA7\u4F4D\u662F\u5426\u6709\u7A7A',
      '\u78BA\u8A8D\u50F9\u5DEE\u8207\u898F\u5247',
      '\u5B8C\u6210\u4ED8\u6B3E\u4E26\u78BA\u8A8D\u6708\u53F0',
    ],
  ),
  ConversationScenario(
    id: 'cafe_order_fix',
    title: 'Cafe Mobile Order Fix',
    titleZh: '\u5496\u5561\u8A02\u55AE\u4FEE\u6B63',
    setting:
        'Your mobile coffee order is wrong, and you only have 10 minutes before class.',
    settingZh:
        '\u4F60\u7684\u5496\u5561\u5916\u9001\u55AE\u6709\u8AA4\uFF0C\u4E14\u4E0A\u8AB2\u524D\u53EA\u522910\u5206\u9418\u3002',
    aiRole: 'Barista',
    aiRoleZh: '\u5496\u5561\u5E97\u54E1',
    userRole: 'Student Customer',
    userRoleZh: '\u5B78\u751F\u9867\u5BA2',
    stages: [
      'Describe the order problem clearly',
      'Ask for a quick remake option',
      'Confirm drink details and add-ons',
      'Ask waiting time',
      'Confirm pickup and thank politely',
    ],
    stagesZh: [
      '\u6E05\u695A\u63CF\u8FF0\u8A02\u55AE\u554F\u984C',
      '\u8A62\u554F\u5FEB\u901F\u91CD\u505A\u65B9\u6848',
      '\u78BA\u8A8D\u98F2\u6599\u7D30\u7BC0\u8207\u52A0\u6599',
      '\u8A62\u554F\u7B49\u5F85\u6642\u9593',
      '\u78BA\u8A8D\u53D6\u9910\u4E26\u79AE\u8C8C\u81F4\u8B1D',
    ],
  ),
  ConversationScenario(
    id: 'supermarket_shopping',
    title: 'Supermarket Shopping',
    titleZh: '\u8D85\u5E02\u8CB7\u83DC',
    setting:
        'You are shopping for dinner ingredients at a supermarket with a fixed budget.',
    settingZh:
        '\u4F60\u5728\u8D85\u5E02\u8CB7\u665A\u9910\u98DF\u6750\uFF0C\u4E14\u6709\u56FA\u5B9A\u9810\u7B97\u3002',
    aiRole: 'Store Assistant',
    aiRoleZh: '\u8D85\u5E02\u5E97\u54E1',
    userRole: 'Shopper',
    userRoleZh: '\u8CFC\u7269\u9867\u5BA2',
    stages: [
      'Ask where to find an item',
      'Compare brands or prices',
      'Ask about discounts',
      'Decide quantity',
      'Confirm checkout choice',
    ],
    stagesZh: [
      '\u8A62\u554F\u5546\u54C1\u5728\u54EA\u88E1',
      '\u6BD4\u8F03\u54C1\u724C\u6216\u50F9\u683C',
      '\u8A62\u554F\u662F\u5426\u6709\u6298\u6263',
      '\u6C7A\u5B9A\u8CFC\u8CB7\u6578\u91CF',
      '\u78BA\u8A8D\u7D50\u5E33\u65B9\u5F0F',
    ],
  ),
  ConversationScenario(
    id: 'library_desk',
    title: 'Library Service Desk',
    titleZh: '\u5716\u66F8\u9928\u6AC3\u53F0',
    setting:
        'You are at a library service desk to borrow, renew, or reserve books.',
    settingZh:
        '\u4F60\u5728\u5716\u66F8\u9928\u6AC3\u53F0\u501F\u66F8\u3001\u7E8C\u501F\u6216\u9810\u7D04\u66F8\u3002',
    aiRole: 'Librarian',
    aiRoleZh: '\u5716\u66F8\u9928\u54E1',
    userRole: 'Student',
    userRoleZh: '\u5B78\u751F',
    stages: [
      'Explain what book you need',
      'Ask loan period and due date',
      'Ask about renewal rules',
      'Ask about reservation wait time',
      'Confirm next action',
    ],
    stagesZh: [
      '\u8AAA\u660E\u4F60\u8981\u627E\u7684\u66F8',
      '\u8A62\u554F\u501F\u95B1\u671F\u9650\u8207\u5230\u671F\u65E5',
      '\u8A62\u554F\u7E8C\u501F\u898F\u5247',
      '\u8A62\u554F\u9810\u7D04\u7B49\u5F85\u6642\u9593',
      '\u78BA\u8A8D\u4E0B\u4E00\u6B65',
    ],
  ),
  ConversationScenario(
    id: 'clinic_appointment',
    title: 'Clinic Appointment',
    titleZh: '\u8A3A\u6240\u639B\u865F',
    setting:
        'You are calling a clinic to schedule an appointment and ask preparation details.',
    settingZh:
        '\u4F60\u6253\u96FB\u8A71\u5230\u8A3A\u6240\u639B\u865F\uFF0C\u4E26\u8A62\u554F\u770B\u8A3A\u524D\u6E96\u5099\u4E8B\u9805\u3002',
    aiRole: 'Receptionist',
    aiRoleZh: '\u6AC3\u53F0\u4EBA\u54E1',
    userRole: 'Patient',
    userRoleZh: '\u75C5\u4EBA',
    stages: [
      'Describe your main symptom',
      'Ask available time slots',
      'Confirm doctor and department',
      'Ask what to bring',
      'Confirm appointment details',
    ],
    stagesZh: [
      '\u63CF\u8FF0\u4E3B\u8981\u75C7\u72C0',
      '\u8A62\u554F\u53EF\u9810\u7D04\u6642\u6BB5',
      '\u78BA\u8A8D\u91AB\u5E2B\u8207\u79D1\u5225',
      '\u8A62\u554F\u9700\u651C\u5E36\u6587\u4EF6',
      '\u78BA\u8A8D\u9810\u7D04\u7D30\u7BC0',
    ],
  ),
  ConversationScenario(
    id: 'restaurant_reservation',
    title: 'Restaurant Reservation',
    titleZh: '\u9910\u5EF3\u8A02\u4F4D',
    setting:
        'You are booking a restaurant table for a small group with seating preferences.',
    settingZh:
        '\u4F60\u8981\u70BA\u5C0F\u5718\u9AD4\u8A02\u4F4D\uFF0C\u4E26\u6709\u5EA7\u4F4D\u504F\u597D\u3002',
    aiRole: 'Restaurant Host',
    aiRoleZh: '\u9910\u5EF3\u63A5\u5F85',
    userRole: 'Guest',
    userRoleZh: '\u8A02\u4F4D\u5BA2\u4EBA',
    stages: [
      'Request date and time',
      'Confirm number of people',
      'Ask for seating preference',
      'Check special requests',
      'Confirm booking name and contact',
    ],
    stagesZh: [
      '\u63D0\u51FA\u65E5\u671F\u8207\u6642\u9593\u9700\u6C42',
      '\u78BA\u8A8D\u7528\u9910\u4EBA\u6578',
      '\u8A62\u554F\u5EA7\u4F4D\u504F\u597D',
      '\u78BA\u8A8D\u7279\u6B8A\u9700\u6C42',
      '\u78BA\u8A8D\u8A02\u4F4D\u59D3\u540D\u8207\u806F\u7D61\u65B9\u5F0F',
    ],
  ),
  ConversationScenario(
    id: 'phone_plan',
    title: 'Phone Plan Advice',
    titleZh: '\u624B\u6A5F\u65B9\u6848\u8AEE\u8A62',
    setting:
        'You are asking a telecom staff to choose a mobile plan that fits your usage.',
    settingZh:
        '\u4F60\u5411\u96FB\u4FE1\u4EBA\u54E1\u8A62\u554F\u9069\u5408\u81EA\u5DF1\u4F7F\u7528\u7FD2\u6163\u7684\u624B\u6A5F\u65B9\u6848\u3002',
    aiRole: 'Telecom Staff',
    aiRoleZh: '\u96FB\u4FE1\u5BA2\u670D',
    userRole: 'Customer',
    userRoleZh: '\u5BA2\u6236',
    stages: [
      'Describe your monthly usage',
      'Compare plan options',
      'Ask about hidden fees',
      'Check contract length',
      'Choose and confirm plan',
    ],
    stagesZh: [
      '\u8AAA\u660E\u6BCF\u6708\u4F7F\u7528\u9700\u6C42',
      '\u6BD4\u8F03\u65B9\u6848\u5167\u5BB9',
      '\u8A62\u554F\u984D\u5916\u8CBB\u7528',
      '\u78BA\u8A8D\u5408\u7D04\u671F\u9593',
      '\u9078\u64C7\u4E26\u78BA\u8A8D\u65B9\u6848',
    ],
  ),
  ConversationScenario(
    id: 'landlord_maintenance',
    title: 'Landlord Maintenance Request',
    titleZh: '\u623F\u6771\u7DAD\u4FEE\u806F\u7D61',
    setting:
        'You are messaging your landlord about a home maintenance problem.',
    settingZh:
        '\u4F60\u6B63\u5728\u806F\u7D61\u623F\u6771\u8655\u7406\u5BB6\u4E2D\u7DAD\u4FEE\u554F\u984C\u3002',
    aiRole: 'Landlord',
    aiRoleZh: '\u623F\u6771',
    userRole: 'Tenant',
    userRoleZh: '\u623F\u5BA2',
    stages: [
      'Describe the issue clearly',
      'Explain urgency and impact',
      'Ask available repair time',
      'Confirm who pays for repair',
      'Confirm appointment details',
    ],
    stagesZh: [
      '\u6E05\u695A\u63CF\u8FF0\u554F\u984C',
      '\u8AAA\u660E\u6025\u8FEB\u6027\u8207\u5F71\u97FF',
      '\u8A62\u554F\u53EF\u7DAD\u4FEE\u6642\u6BB5',
      '\u78BA\u8A8D\u8CBB\u7528\u7531\u8AB0\u8CA0\u64D4',
      '\u78BA\u8A8D\u5230\u5E9C\u6642\u9593',
    ],
  ),
  ConversationScenario(
    id: 'class_registration',
    title: 'Class Registration Help',
    titleZh: '\u8AB2\u7A0B\u52A0\u9000\u9078\u8AEE\u8A62',
    setting:
        'You are asking academic staff about adding a class and schedule conflicts.',
    settingZh:
        '\u4F60\u5411\u6559\u52D9\u4EBA\u54E1\u8A62\u554F\u52A0\u9078\u8AB2\u7A0B\u8207\u6642\u6BB5\u885D\u7A81\u554F\u984C\u3002',
    aiRole: 'Academic Staff',
    aiRoleZh: '\u6559\u52D9\u4EBA\u54E1',
    userRole: 'Student',
    userRoleZh: '\u5B78\u751F',
    stages: [
      'State the class you want',
      'Explain your schedule conflict',
      'Ask alternative sections',
      'Check registration deadline',
      'Confirm required steps',
    ],
    stagesZh: [
      '\u8AAA\u660E\u60F3\u52A0\u9078\u7684\u8AB2\u7A0B',
      '\u89E3\u91CB\u6642\u6BB5\u885D\u7A81',
      '\u8A62\u554F\u66FF\u4EE3\u73ED\u5225',
      '\u78BA\u8A8D\u52A0\u9000\u9078\u671F\u9650',
      '\u78BA\u8A8D\u8FA6\u7406\u6D41\u7A0B',
    ],
  ),
];
