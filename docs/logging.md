## Logging

When generating new code, classes, functions, or files:

### Development Log

Record the following information:

* Main features of the generated code
* Functionalities implemented
* Important design decisions
* Modified files
* Newly created files
* put log file in logs/developementLogs

### User Feedback Log

Record user feedback, including:

* Preferences
* Opinions
* Coding style requirements
* Architecture requirements
* put log file in logs/feedbackLogs
### Error Log

If the user reports problems or expresses dissatisfaction with generated code:

Record:

* The issue
* The root cause
* What should be avoided in future implementations
* put log file in logs/errorLogs
Do not repeat previously recorded mistakes.

### Log Storage

Maintain development logs in a dedicated file.

Preferred formats:

* Markdown (.md) - best
* JSON (.json)
* Text (.txt)
* filename example:development_20260531_120000
Update the log whenever significant code changes are made.
Please put logfile in  their corresponging folder,example:errorlog put in /logs/errorLogs,Development log put in /logs/developementLogs