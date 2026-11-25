import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veridian/providers/localization_provider.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Расширенная база данных FAQ
  final Map<String, List<Map<String, String>>> _faqData = {
    'ru': [
      {
        'question': 'Как сменить пароль от приложения?',
        'answer':
            'Для смены пароля перейдите в раздел "Профиль" (нажмите на ваше имя вверху главной страницы), затем выберите "Настройки" -> "Безопасность" -> "Сменить пароль". Вам потребуется ввести текущий пароль, а затем дважды новый. Если вы забыли текущий пароль, выйдите из приложения и воспользуйтесь функцией "Забыли код?" на экране входа.'
      },
      {
        'question': 'Как открыть новую карту или счет?',
        'answer':
            'Вы можете открыть карту онлайн за пару минут. На главной странице найдите раздел "Карты" или "Счета", нажмите на иконку "+" (плюс). Выберите тип карты (Дебетовая, Кредитная или Виртуальная), валюту счета и подтвердите открытие кодом из SMS. Виртуальная карта будет доступна для использования мгновенно.'
      },
      {
        'question': 'Какие существуют лимиты на переводы?',
        'answer':
            'Стандартные лимиты для физических лиц:\n\n• Внутри банка: без ограничений.\n• На карты других банков РК: до 1 000 000 ₸ в сутки.\n• Международные переводы: до 5 000 USD в сутки.\n\nВы можете самостоятельно управлять лимитами в настройках конкретной карты. Для увеличения лимитов сверх стандартных, пожалуйста, обратитесь в отделение банка или видео-банкинг.'
      },
      {
        'question': 'Как заблокировать карту при утере?',
        'answer':
            'Если вы потеряли карту или подозреваете кражу данных, немедленно заблокируйте её. Для этого:\n1. Перейдите в раздел "Карты".\n2. Выберите нужную карту.\n3. Нажмите кнопку "Заблокировать" (иконка замка).\n\nБлокировка происходит мгновенно. Если карта найдется, вы сможете так же быстро разблокировать её в приложении.'
      },
      {
        'question': 'Как оплатить кредит или посмотреть график?',
        'answer':
            'Вся информация по кредитам находится в разделе "Кредиты". Нажмите на активный кредит, чтобы увидеть детальную информацию: сумму долга, процентную ставку, дату следующего платежа и график погашения. Чтобы внести платеж, нажмите кнопку "Внести платеж" и выберите счет списания.'
      },
      {
        'question': 'Что такое CVV код и где его найти?',
        'answer':
            'CVV/CVC (Card Verification Value) — это трехзначный код безопасности, необходимый для онлайн-покупок. На физической карте он напечатан на обратной стороне. Для виртуальных карт вы можете посмотреть CVV в приложении: выберите карту, нажмите "Реквизиты" и подтвердите действие биометрией или кодом.'
      },
      {
        'question': 'Как работают мобильные платежи (QR и NFC)?',
        'answer':
            '• QR: Нажмите кнопку "QR" в нижнем меню, наведите камеру на код продавца и подтвердите сумму.\n• NFC: Убедитесь, что NFC включен в настройках телефона. Нажмите "NFC оплата" в приложении и поднесите телефон к терминалу.\nДля работы NFC карта должна быть добавлена в Google Pay или Apple Pay.'
      },
      {
        'question': 'Как связаться с поддержкой?',
        'answer':
            'Мы на связи 24/7. Вы можете:\n1. Написать в чат в разделе "Поддержка".\n2. Позвонить по бесплатному номеру 9090 (с мобильного).\n3. Заказать обратный звонок через меню "Еще".'
      },
      {
        'question': 'Безопасно ли использовать приложение?',
        'answer':
            'Абсолютно. Veridian использует передовые стандарты шифрования данных. Мы поддерживаем вход по Touch ID / Face ID. Никогда не сообщайте никому свой ПИН-код, пароли из SMS и CVV-код карты, даже сотрудникам банка.'
      },
      {
        'question': 'Как получить справку о наличии счета?',
        'answer':
            'Вам не нужно идти в отделение. Откройте нужный счет или карту -> "Настройки" (или "Еще") -> "Заказать справку". Выберите тип справки и язык. Документ в формате PDF будет готов в течение минуты, и вы сможете отправить его через мессенджеры или на почту.'
      },
    ],
    'kk': [
      {
        'question': 'Қолданбаның құпия сөзін қалай өзгертуге болады?',
        'answer':
            'Құпия сөзді өзгерту үшін "Профиль" бөліміне өтіңіз (басты беттегі атыңызды басыңыз), содан кейін "Баптаулар" -> "Қауіпсіздік" -> "Құпия сөзді өзгерту" тармағын таңдаңыз. Сізге ағымдағы құпия сөзді, содан кейін жаңасын екі рет енгізу қажет болады. Егер ескі кодты ұмытып қалсаңыз, шығып, кіру экранындағы "Кодты ұмыттыңыз ба?" түймесін басыңыз.'
      },
      {
        'question': 'Жаңа карта немесе шотты қалай ашуға болады?',
        'answer':
            'Картаны онлайн бірнеше минут ішінде ашуға болады. Басты бетте "Карталар" немесе "Шоттар" бөлімін тауып, "+" белгішесін басыңыз. Карта түрін (Дебеттік, Кредиттік немесе Виртуалды) және валютаны таңдап, SMS кодымнен растаңыз. Виртуалды карта бірден қолдануға дайын болады.'
      },
      {
        'question': 'Аударымдар бойынша қандай лимиттер бар?',
        'answer':
            'Жеке тұлғалар үшін стандартты лимиттер:\n\n• Банк ішінде: шектеусіз.\n• ҚР басқа банктерінің карталарына: тәулігіне 1 000 000 ₸ дейін.\n• Халықаралық аударымдар: тәулігіне 5 000 USD дейін.\n\nЛимиттерді карта баптауларында өзіңіз басқара аласыз. Лимитті көтеру үшін бөлімшеге немесе бейне-банкингке хабарласыңыз.'
      },
      {
        'question': 'Карта жоғалған жағдайда қалай бұғаттауға болады?',
        'answer':
            'Егер картаны жоғалтсаңыз немесе ұрлыққа күдіктенсеңіз, оны дереу бұғаттаңыз. Ол үшін:\n1. "Карталар" бөліміне өтіңіз.\n2. Қажетті картаны таңдаңыз.\n3. "Бұғаттау" (құлып белгішесі) түймесін басыңыз.\n\nБұғаттау лезде орындалады. Карта табылса, оны қолданба арқылы қайта іске қосуға болады.'
      },
      {
        'question': 'Несиені қалай төлеуге немесе кестені көруге болады?',
        'answer':
            'Несиелер бойынша барлық ақпарат "Несиелер" бөлімінде. Қалдық соманы, мөлшерлемені, төлем күнін және кестені көру үшін белсенді несиені басыңыз. Төлем жасау үшін "Төлем жасау" түймесін басып, қаражат алынатын шотты таңдаңыз.'
      },
      {
        'question': 'CVV код деген не және оны қайдан табуға болады?',
        'answer':
            'CVV/CVC — интернетте төлем жасауға арналған үш таңбалы қауіпсіздік коды. Пластикалық картада ол артқы жағында жазылған. Виртуалды карталар үшін кодты қолданбадан көре аласыз: картаны таңдап, "Реквизиттер" бөліміне өтіп, биометриямен растаңыз.'
      },
      {
        'question': 'Мобильді төлемдер (QR және NFC) қалай жұмыс істейді?',
        'answer':
            '• QR: Төменгі мәзірден "QR" түймесін басып, сатушының кодын сканерлеңіз.\n• NFC: Телефон баптауларында NFC қосулы екенін тексеріңіз. Қолданбада "NFC төлем" басып, телефонды терминалға жақындатыңыз. NFC жұмыс істеуі үшін карта Google Pay немесе Apple Pay жүйесіне қосылған болуы керек.'
      },
      {
        'question': 'Қолдау қызметімен қалай байланысуға болады?',
        'answer':
            'Біз тәулік бойы байланыстамыз:\n1. "Қолдау" бөліміндегі чатқа жазыңыз.\n2. 9090 тегін нөміріне қоңырау шалыңыз.\n3. "Тағы" мәзірі арқылы кері қоңырауға тапсырыс беріңіз.'
      },
      {
        'question': 'Қолданбаны пайдалану қауіпсіз бе?',
        'answer':
            'Әрине. Veridian деректерді шифрлаудың озық стандарттарын қолданады. Touch ID / Face ID арқылы кіру қорғалған. ПИН-кодты, SMS құпия сөздерін және CVV кодын ешкімге, тіпті банк қызметкерлеріне де айтпаңыз.'
      },
      {
        'question': 'Шоттың бар екендігі туралы анықтаманы қалай алуға болады?',
        'answer':
            'Бөлімшеге барудың қажеті жоқ. Қажетті шотты немесе картаны ашыңыз -> "Баптаулар" -> "Анықтама алу". Анықтама түрі мен тілін таңдаңыз. PDF құжат бір минут ішінде дайын болады.'
      },
    ],
    'en': [
      {
        'question': 'How to change the app password?',
        'answer':
            'To change your password, go to the "Profile" section (tap your name at the top of the Home screen), then select "Settings" -> "Security" -> "Change Password". You will need to enter your current password and then the new one twice. If you forgot your current password, log out and use the "Forgot code?" feature on the login screen.'
      },
      {
        'question': 'How to open a new card or account?',
        'answer':
            'You can open a card online in minutes. On the Home screen, find the "Cards" or "Accounts" section and tap the "+" icon. Select the card type (Debit, Credit, or Virtual), account currency, and confirm via SMS code. Virtual cards are available for use instantly.'
      },
      {
        'question': 'What are the transfer limits?',
        'answer':
            'Standard limits for individuals:\n\n• Internal transfers: Unlimited.\n• To other KZ bank cards: up to 1,000,000 ₸ per day.\n• International transfers: up to 5,000 USD per day.\n\nYou can manage limits in the card settings. To increase limits beyond standard ones, please contact a branch or video banking.'
      },
      {
        'question': 'How to block a lost card?',
        'answer':
            'If you lost your card or suspect data theft, block it immediately. To do this:\n1. Go to "Cards".\n2. Select the card.\n3. Tap the "Block" button (lock icon).\n\nBlocking is instant. If you find the card, you can unblock it just as quickly in the app.'
      },
      {
        'question': 'How to pay a loan or view the schedule?',
        'answer':
            'All loan information is in the "Loans" section. Tap on an active loan to see details: remaining balance, interest rate, next payment date, and schedule. To make a payment, tap "Make Payment" and select the source account.'
      },
      {
        'question': 'What is a CVV code and where to find it?',
        'answer':
            'CVV/CVC is a 3-digit security code for online purchases. On a physical card, it is printed on the back. For virtual cards, you can view it in the app: select the card, tap "Details", and confirm with biometrics or code.'
      },
      {
        'question': 'How do mobile payments (QR and NFC) work?',
        'answer':
            '• QR: Tap the "QR" button in the bottom menu, scan the merchant\'s code, and confirm.\n• NFC: Ensure NFC is enabled in phone settings. Tap "NFC Payment" in the app and hold your phone near the terminal. For NFC, the card must be added to Google Pay or Apple Pay.'
      },
      {
        'question': 'How to contact support?',
        'answer':
            'We are available 24/7. You can:\n1. Write to the chat in the "Support" section.\n2. Call the free number 9090.\n3. Request a callback via the "More" menu.'
      },
      {
        'question': 'Is the app secure?',
        'answer':
            'Yes. Veridian uses advanced data encryption standards. We support Touch ID / Face ID login. Never share your PIN, SMS codes, or CVV with anyone, even bank employees.'
      },
      {
        'question': 'How to get an account statement or certificate?',
        'answer':
            'No need to visit a branch. Open the account or card -> "Settings" -> "Order Certificate". Select the type and language. The PDF document will be ready in a minute, and you can share it via messengers or email.'
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);

    // Получаем список вопросов для текущего языка
    final currentLangCode =
        localization.currentLanguage.name; // 'ru', 'en', 'kk'
    final faqList = _faqData[currentLangCode] ?? _faqData['ru']!;

    // Фильтрация по поиску
    final filteredList = faqList.where((item) {
      final q = item['question']!.toLowerCase();
      final a = item['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return q.contains(query) || a.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localization.translate('faq_title'),
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Поле поиска
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: localization.translate('faq_search'),
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // Список вопросов
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      localization.translate('no_results_found'),
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Theme(
                          // Убираем дефолтные линии разделителя в ExpansionTile
                          data:
                              theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: theme.primaryColor,
                            collapsedIconColor:
                                theme.colorScheme.onSurfaceVariant,
                            title: Text(
                              item['question']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item['answer']!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                      height:
                                          1.5, // Межстрочный интервал для читаемости
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
