import '../../l10n/app_localizations.dart';

extension HomeworkL10n on AppLocalizations {
  bool get _isIt => localeName.startsWith('it');
  bool get _isBn => localeName.startsWith('bn');

  String get homeworkTitle => _isIt
      ? 'Compiti'
      : _isBn
          ? 'হোমওয়ার্ক'
          : 'Homework';

  String get homeworkActiveNow => _isIt
      ? 'Attivi ora'
      : _isBn
          ? 'এখন সক্রিয়'
          : 'Active Now';

  String get homeworkUpcoming => _isIt
      ? 'In arrivo'
      : _isBn
          ? 'আসন্ন'
          : 'Upcoming';

  String get homeworkCompleted => _isIt
      ? 'Completati'
      : _isBn
          ? 'সম্পন্ন'
          : 'Completed';

  String get homeworkViewDetails => _isIt
      ? 'Dettagli'
      : _isBn
          ? 'বিস্তারিত'
          : 'View Details';

  String get homeworkStart => _isIt
      ? 'Inizia'
      : _isBn
          ? 'শুরু করুন'
          : 'Start';

  String get homeworkStartLabel => _isIt
      ? 'Inizia compito'
      : _isBn
          ? 'হোমওয়ার্ক শুরু করুন'
          : 'Start Homework';

  String get homeworkRetry => _isIt
      ? 'Riprova'
      : _isBn
          ? 'পুনরায় দিন'
          : 'Retry';

  String get homeworkLeaderboard => _isIt
      ? 'Classifica'
      : _isBn
          ? 'লিডারবোর্ড'
          : 'Leaderboard';

  String get homeworkViewResult => _isIt
      ? 'Vedi risultato'
      : _isBn
          ? 'ফলাফল দেখুন'
          : 'View Result';

  String get homeworkNoItems => _isIt
      ? 'Nessun compito disponibile.'
      : _isBn
          ? 'কোনো হোমওয়ার্ক পাওয়া যায়নি।'
          : 'No homework available.';

  String get homeworkQuestionCount => _isIt
      ? 'Domande'
      : _isBn
          ? 'প্রশ্ন'
          : 'Questions';

  String get homeworkTimeLimit => _isIt
      ? 'Tempo'
      : _isBn
          ? 'সময়সীমা'
          : 'Time limit';

  String get homeworkTimeRemaining => _isIt
      ? 'Tempo rimanente'
      : _isBn
          ? 'বাকি সময়'
          : 'Time remaining';

  String get homeworkStartsIn => _isIt
      ? 'Inizia tra'
      : _isBn
          ? 'শুরু হবে'
          : 'Starts in';

  String get homeworkSubmitted => _isIt
      ? 'Inviato'
      : _isBn
          ? 'জমা দেওয়া হয়েছে'
          : 'Submitted';

  String get homeworkStatus => _isIt
      ? 'Stato'
      : _isBn
          ? 'স্ট্যাটাস'
          : 'Status';

  String get homeworkStartDate => _isIt
      ? 'Inizio'
      : _isBn
          ? 'শুরুর সময়'
          : 'Start';

  String get homeworkEndDate => _isIt
      ? 'Fine'
      : _isBn
          ? 'শেষ সময়'
          : 'End';

  String get homeworkRetryAllowed => _isIt
      ? 'Riprova consentita'
      : _isBn
          ? 'পুনরায় দেওয়া যাবে'
          : 'Retry allowed';

  String get homeworkNotSubmittedYet => _isIt
      ? 'Non inviato'
      : _isBn
          ? 'এখনও জমা দেওয়া হয়নি'
          : 'Not submitted yet';

  String get homeworkStartWarningTitle => _isIt
      ? 'Conferma avvio'
      : _isBn
          ? 'শুরুর নিশ্চয়তা'
          : 'Confirm Start';

  String get homeworkStartWarningMessage => _isIt
      ? 'Questo compito può essere svolto una sola volta. Sei sicuro di voler iniziare?'
      : _isBn
          ? 'এই হোমওয়ার্কটি শুধুমাত্র একবার দেওয়া যাবে। আপনি কি শুরু করতে চান?'
          : 'This homework can only be attempted once. Are you sure you want to start?';

  String get homeworkBackToList => _isIt
      ? 'Torna ai compiti'
      : _isBn
          ? 'হোমওয়ার্কে ফিরে যান'
          : 'Back to Homework';

  String get homeworkReviewAnswers => _isIt
      ? 'Rivedi risposte'
      : _isBn
          ? 'উত্তর রিভিউ করুন'
          : 'Review Answers';

  String get homeworkRank => _isIt
      ? 'Posizione'
      : _isBn
          ? 'র‍্যাঙ্ক'
          : 'Rank';

  String get homeworkYes => _isIt
      ? 'Sì'
      : _isBn
          ? 'হ্যাঁ'
          : 'Yes';

  String get homeworkNo => _isIt
      ? 'No'
      : _isBn
          ? 'না'
          : 'No';

  String get homeworkFailedToStart => _isIt
      ? 'Impossibile avviare il compito'
      : _isBn
          ? 'হোমওয়ার্ক শুরু করা যায়নি'
          : 'Failed to start homework';
}
