class Question {
  String question;
  String answer;
  List<String> choices;

  Question(this.question, this.answer, [this.choices = const []]);
}