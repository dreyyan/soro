class Question {
  String question;
  String answer;
  List<String> choices;
  String type;
  bool trueFalseAnswer;

  Question(
    this.question,
    this.answer, [
    this.choices = const [],
    this.type = "Multiple Choice",
    this.trueFalseAnswer = true,
  ]);
}