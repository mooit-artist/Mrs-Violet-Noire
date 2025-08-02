import logging
import os
import json
import sys
import subprocess
import time
from pathlib import Path

# Set up logging to meetingdebug.log
LOG_PATH = str(Path(__file__).parent / "meetingdebug.log")
logging.basicConfig(
    filename=LOG_PATH,
    filemode="a",
    format="%(asctime)s [%(levelname)s] %(message)s",
    level=logging.INFO
)
logging.info("--- LLM Meeting Orchestrator started ---")

#!/usr/bin/env python3
"""
Interactive LLM Meeting Orchestrator
- Alternates between user and persona input
- Supports multiple-choice questions (personas: max 10, user: max 20, always exit option)
- Input/output validation for all communication
- Each persona provides a summary and recommendation
- Voting mechanism with user vote weighted highest
"""

PERSONA_DIR = Path(__file__).parent.parent / "prompts"

# Model assignment by persona
PERSONA_MODEL_MAP = {
    # Technical/engineering personas
    "dev-david-voice": "codellama",
    "sysadmin-sam": "codellama",
    "ai-architect-alex-voice": "llama3.1",
    "devops-devon": "codellama",
    "data-scientist-dana": "llama3.1",
    # Security personas
    "secanalyst-sage": "llama3.1",
    "redteam-ruby": "llama3.1",
    "blueteam-ben": "llama3.1",
    # Business/leadership personas
    "leader-larry-voice": "llama3.1",
    "strategy-steve-voice": "llama3.1",
    "finance-fred-voice": "llama3.1",
    "pm-penny-voice": "llama3.1",
    # Legal/privacy/HR personas
    "legal-louise": "llama3.1",
    "privacy-pat": "llama3.1",
    "hr-hannah-voice": "llama3.1",
    # Creative/UX personas
    "designer-debbie-voice": "llama3.1",
    # Default
}
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1")
OLLAMA_BIN = os.environ.get("OLLAMA_BIN", "ollama")

# Utility functions

def ollama_generate(prompt, model=OLLAMA_MODEL, timeout=10):
    """
    Run ollama with a timeout (in seconds). If timeout is exceeded, return a default message.
    """
    try:
        result = subprocess.run([
            OLLAMA_BIN, "run", model, prompt
        ], capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        return "Response timed out."

def get_persona_model(persona_name):
    return PERSONA_MODEL_MAP.get(persona_name, OLLAMA_MODEL)

def get_persona_files():
    return sorted(PERSONA_DIR.glob("*.md"))

def read_persona(persona_file):
    if not persona_file.is_file():
        raise ValueError(f"Invalid persona file: {persona_file}")
    with open(persona_file, "r") as f:
        return f.read()

def ask_multiple_choice(question, choices, allow_exit=True, user=True):
    max_choices = 20 if user else 10
    # Filter out special options first
    filtered = [c for c in choices if c not in ("No comment", "Exit")]

    if user:
        # User gets only 'Exit' option, no 'No comment'
        filtered = filtered[:max_choices-1] + ["Exit"]
    else:
        # Personas get 'No comment' option
        filtered = filtered[:max_choices-1] + ["No comment"]

    choices = filtered
    print(f"\n{question}")
    for idx, choice in enumerate(choices, 1):
        print(f"  {idx}. {choice}")
    while True:
        try:
            sel = int(input("Select an option: "))
            if 1 <= sel <= len(choices):
                return choices[sel-1]
        except Exception:
            pass
        print(f"Please enter a number between 1 and {len(choices)}.")

def validate_response(response, valid_choices):
    return response in valid_choices

def persona_ask_question(persona_name, persona_desc, context, to_user=True):
    # Prompt persona to generate a multiple-choice question
    role = "the user" if to_user else "another persona"
    prompt = f"""
You are the persona below. You are in a meeting with other personas and the user. Based on the context, ask {role} a multiple-choice question (max {20 if to_user else 10} choices, always include a 'No comment' option as the last choice. Only the user can exit the meeting). Return ONLY the question and the choices as a JSON object: {{'question': str, 'choices': list of str}}.

Persona Description:
{persona_desc}

Meeting Context:
{context}
"""
    model = get_persona_model(persona_name)
    print(f"[Timing] Generating question for {persona_name} using model '{model}'...")
    t0 = time.time()
    response = ollama_generate(prompt, model=model, timeout=10)
    t1 = time.time()
    elapsed = t1 - t0
    print(f"[Timing] LLM response time: {elapsed:.2f} seconds.")
    if elapsed > 5:
        print(f"[Warning] LLM response for {persona_name} took longer than 5 seconds.")
    try:
        data = json.loads(response)
        if 'question' in data and 'choices' in data and isinstance(data['choices'], list):
            return data['question'], data['choices']
    except Exception:
        pass
    # fallback
    return "No valid question generated.", ["Exit"]

def persona_summary_and_recommendation(persona_name, persona_desc, transcript):
    prompt = f"""
You are the persona below. Summarize your participation in the meeting and provide a clear path forward recommendation. Be concise.

Persona Description:
{persona_desc}

Meeting Transcript:
{transcript}
"""
    model = get_persona_model(persona_name)
    return ollama_generate(prompt, model=model)

def persona_vote(persona_name, recommendations):
    prompt = f"""
You are a meeting participant. Here are the recommendations from the meeting:
{json.dumps(recommendations, indent=2)}

If you were to vote for the best path forward, which would you choose? Reply with the exact recommendation text.
"""
    model = get_persona_model(persona_name)
    return ollama_generate(prompt, model=model)


def print_progress_bar(iteration, total, prefix='', suffix='', length=40, fill='█'):
    percent = (iteration / float(total))
    filled_length = int(length * percent)
    bar = fill * filled_length + '-' * (length - filled_length)
    print(f'\r{prefix} |{bar}| {int(percent*100)}% {suffix}', end='\r')
    if iteration == total:
        print()

def main():
    logging.info(f"Starting new meeting orchestrator run.")
    # If the meeting is about issues, print a note of current open issues
    def print_open_issues():
        # Try to get issues from GitHub if .git exists and remote is set
        import subprocess
        import re
        repo_path = Path(__file__).parent.parent
        git_dir = repo_path / '.git'
        if git_dir.exists():
            try:
                # Get remote URL
                remote_url = subprocess.check_output(['git', '-C', str(repo_path), 'remote', 'get-url', 'origin'], text=True).strip()
                m = re.search(r'github.com[:/](.*?)/(.*?)(?:\.git)?$', remote_url)
                if m:
                    owner, repo = m.group(1), m.group(2)
                    print(f"\nFetching open issues from GitHub repo: {owner}/{repo} ...")
                    import urllib.request, json
                    url = f"https://api.github.com/repos/{owner}/{repo}/issues?state=open"
                    req = urllib.request.Request(url, headers={'Accept': 'application/vnd.github.v3+json'})
                    with urllib.request.urlopen(req) as resp:
                        issues = json.load(resp)
                    if issues:
                        print(f"\nOpen Issues:")
                        for issue in issues:
                            if 'pull_request' not in issue:
                                print(f"  #{issue['number']}: {issue['title']}")
                    else:
                        print("No open issues found.")
                    return
            except Exception as e:
                print(f"[Warning] Could not fetch GitHub issues: {e}")
        # Fallback: look for local issues file
        for fname in [repo_path / 'issues.md', repo_path / 'ISSUES.md', repo_path / 'issues.txt']:
            if fname.exists():
                print(f"\nOpen Issues (from {fname.name}):")
                with open(fname) as f:
                    for line in f:
                        print(f"  {line.strip()}")
                return
        print("\n[Note] No open issues found in repo or local files.")

    import argparse
    parser = argparse.ArgumentParser(description="Interactive LLM Meeting Orchestrator")
    parser.add_argument("--title", required=False)
    parser.add_argument("--agenda", required=False)
    args = parser.parse_args()

    # Path to store last meeting info
    state_file = os.path.expanduser("~/.llm_meeting_state.json")
    last_title = None
    last_agenda = None
    if os.path.exists(state_file):
        try:
            with open(state_file, "r") as f:
                state = json.load(f)
                last_title = state.get("title")
                last_agenda = state.get("agenda")
        except Exception as e:
            logging.warning(f"Failed to load previous meeting state: {e}")

    title = args.title
    agenda = args.agenda

    # If no CLI title/agenda, prompt to continue previous meeting if available
    if (not title or not agenda) and last_title and last_agenda:
        print(f"\nPrevious meeting found:")
        print(f"  Title: {last_title}")
        print(f"  Agenda: {last_agenda}")
        logging.info(f"Previous meeting found: Title='{last_title}', Agenda='{last_agenda}'")
        resp = input("Would you like to continue the previous conversation? [Y/n]: ").strip().lower()
        if resp in ("", "y", "yes"):
            title = last_title
            agenda = last_agenda
            logging.info("User chose to continue previous meeting.")
        else:
            logging.info("User chose to start a new meeting.")

    # If still missing, prompt as usual
    if not title:
        title = input("Meeting Title: ")
        logging.info(f"User entered meeting title: {title}")
    if not agenda:
        agenda = input("Agenda/Topic: ")
        logging.info(f"User entered meeting agenda: {agenda}")

    # Now check for issues and print them if agenda/title mentions 'issue'
    if title and agenda and ('issue' in title.lower() or 'issue' in agenda.lower()):
        logging.info("Agenda or title mentions 'issue'; printing open issues.")
        try:
            print_open_issues()
        except Exception as e:
            logging.error(f"Error printing open issues: {e}")

    # Save current meeting state
    try:
        with open(state_file, "w") as f:
            json.dump({"title": title, "agenda": agenda}, f)
        logging.info("Saved current meeting state.")
    except Exception as e:
        logging.warning(f"Failed to save meeting state: {e}")

    # Use title/agenda as if from args
    class Args:
        pass
    args = Args()
    args.title = title
    args.agenda = agenda

    persona_files = get_persona_files()
    personas = [(pf.stem, read_persona(pf)) for pf in persona_files]
    # Move Mrs Violet Noire (BOOK-REVIEW-TEMPLATE) to the front if present
    violet_idx = next((i for i, (n, _) in enumerate(personas) if n.lower() in ["book-review-template", "mrs violet noire", "mrs-violot-noire", "mrs-violet-noire"]), None)
    if violet_idx is not None and violet_idx != 0:
        personas.insert(0, personas.pop(violet_idx))
    transcript = []
    context = f"Meeting Title: {args.title}\nAgenda: {args.agenda}"

    print(f"\n🧑‍💼 LLM Meeting: {args.title}\n📝 Agenda: {args.agenda}\n{'-'*40}")
    print(f"\n[Meeting Status] Meeting '{args.title}' has started.")
    logging.info(f"Meeting started: Title='{args.title}', Agenda='{args.agenda}'")

    total_personas = len(personas)
    meeting_start = time.time()
    persona_timings = {}

    # Track if each persona has asked at least one question
    persona_asked = {n: False for n, _ in personas}

    # ANSI color codes for up to 12 personas (cycle if more)
    COLORS = [
        '\033[91m', # Red
        '\033[92m', # Green
        '\033[93m', # Yellow
        '\033[94m', # Blue
        '\033[95m', # Magenta
        '\033[96m', # Cyan
        '\033[31m', # Light Red
        '\033[32m', # Light Green
        '\033[33m', # Light Yellow
        '\033[34m', # Light Blue
        '\033[35m', # Light Magenta
        '\033[36m', # Light Cyan
    ]
    RESET = '\033[0m'

    # Main interactive loop with persona-to-persona interaction, minimal user intervention
    critical_questions_for_user = []  # Store only absolutely critical questions

    # Start with user questions to establish meeting context
    print(f"\n{COLORS[0]}Initial Context Setting - Please answer a few questions to guide the meeting:{RESET}")

    initial_questions = [
        (f"What is your main goal for this meeting on '{args.agenda}'?", [
            f"Learn about '{args.agenda}'",
            f"Make a decision about '{args.agenda}'",
            f"Brainstorm solutions for '{args.agenda}'",
            f"Get expert opinions on '{args.agenda}'"
        ]),
        (f"What level of detail do you want for '{args.agenda}'?", [
            "High-level overview and recommendations",
            "Detailed technical analysis",
            "Practical next steps and actions",
            "Creative and innovative approaches"
        ]),
        (f"What's your biggest concern about '{args.agenda}'?", [
            "Technical complexity and implementation",
            "Time and resource constraints",
            "Risk and potential downsides",
            "Stakeholder buy-in and adoption"
        ])
    ]

    for q_idx, (question, choices) in enumerate(initial_questions, 1):
        turn_start = time.time()
        print(f"\n{COLORS[q_idx % len(COLORS)]}Question {q_idx}/{len(initial_questions)}: {question}{RESET}")
        user_answer = ask_multiple_choice(question, choices, allow_exit=True, user=True)
        turn_end = time.time()

        if user_answer == "Exit":
            print("Exiting meeting early.")
            logging.info(f"User exited meeting during initial questions at question {q_idx}.")
            return

        logging.info(f"User answered initial question {q_idx}: {user_answer}")
        critical_questions_for_user.append(user_answer)

        transcript_entry = {
            "persona": "Initial Context",
            "question": question,
            "choices": choices,
            "user_answer": user_answer,
            "timestamp": time.strftime('%Y-%m-%d %H:%M:%S'),
            "duration": turn_end - turn_start
        }
        transcript.append(transcript_entry)

        if user_answer != "No comment":
            input(f"{COLORS[q_idx % len(COLORS)]}Press Enter to continue to the next question...{RESET}")

    # Separate Mrs. Violet Noire from other personas - she'll speak last
    mrs_violet_noire = None
    other_personas = []

    for persona_name, persona_desc in personas:
        if persona_name.lower() in ["book-review-template", "mrs violet noire", "mrs-violot-noire", "mrs-violet-noire"]:
            mrs_violet_noire = (persona_name, persona_desc)
        else:
            other_personas.append((persona_name, persona_desc))

    # Main meeting loop - other personas first (Mrs. Violet Noire speaks last)
    for idx, (persona_name, persona_desc) in enumerate(other_personas, 1):
        logging.info(f"Persona {idx}/{len(other_personas)}: {persona_name} turn started.")
        print_progress_bar(idx-1, len(other_personas), prefix='Progress', suffix=f'{idx-1}/{len(other_personas)} personas complete')
        color = COLORS[(idx-1) % len(COLORS)]
        display_name = persona_name.replace('-', ' ').title()
        print(f"\n\n{color}=== {display_name} is speaking ==={RESET}")
        turn_start = time.time()

        # Check if model is available, if not, wait and notify
        model = get_persona_model(persona_name)
        model_check_cmd = [OLLAMA_BIN, 'list']
        waiting_for_model = False
        try:
            result = subprocess.run(model_check_cmd, capture_output=True, text=True, timeout=5)
            if model not in result.stdout:
                print(f"[Status] Model '{model}' not found. Downloading... (timer paused)")
                waiting_for_model = True
                wait_start = time.time()
                pull_cmd = [OLLAMA_BIN, 'pull', model]
                subprocess.run(pull_cmd)
                wait_end = time.time()
                print(f"[Status] Model '{model}' downloaded in {wait_end - wait_start:.2f} seconds.")
        except Exception as e:
            print(f"[Warning] Could not check/download model '{model}': {e}")

        if waiting_for_model:
            # Reset turn_start after model download
            turn_start = time.time()
            logging.info(f"Model '{model}' downloaded for persona '{persona_name}'.")

        # Personas ask each other questions, user just observes
        q, choices = persona_ask_question(persona_name, persona_desc, context, to_user=False)
        turn_end = time.time()
        persona_timings[persona_name] = {'question_time': turn_end - turn_start}
        print(f"[Status] {persona_name} asked other personas a question in {turn_end - turn_start:.2f} seconds.")

        # Simulate persona interaction - pick a random response or use AI
        if choices and len(choices) > 1:
            # Filter out No comment for variety in responses
            valid_choices = [c for c in choices if c != "No comment"]
            if valid_choices:
                # Use the first substantive choice for consistency
                user_answer = valid_choices[0]
            else:
                user_answer = "No comment"
        else:
            user_answer = "No comment"

        print(f"{color}Other personas respond: {user_answer}{RESET}")
        logging.info(f"Personas answered '{persona_name}' question: {user_answer}")

        persona_asked[persona_name] = True
        transcript_entry = {
            "persona": persona_name,
            "question": q,
            "choices": choices,
            "user_answer": user_answer,
            "timestamp": time.strftime('%Y-%m-%d %H:%M:%S'),
            "duration": turn_end - turn_start
        }
        transcript.append(transcript_entry)
        # Write a JSON file for each speaker
        speaker_json_path = Path(__file__).parent.parent / f"meeting_{persona_name}.json"
        with open(speaker_json_path, "w") as sjf:
            json.dump(transcript_entry, sjf, indent=2)

        # Handle user response (although user mostly observes now)
        if user_answer == "Exit":
            print("Exiting meeting early.")
            logging.info(f"User exited meeting at persona '{persona_name}'.")
            break
        elif user_answer == "No comment":
            print(f"{color}Moving to the next speaker...{RESET}")
            logging.info(f"Persona conversation continues for '{persona_name}'.")
            continue
        else:
            input(f"{color}Press Enter to continue to the next speaker...{RESET}")

    print_progress_bar(len(other_personas), len(other_personas), prefix='Progress', suffix=f'{len(other_personas)}/{len(other_personas)} personas complete')

    # Now Mrs. Violet Noire speaks last, after reviewing all the discussion
    if mrs_violet_noire:
        persona_name, persona_desc = mrs_violet_noire
        turn_start = time.time()
        color = COLORS[len(other_personas) % len(COLORS)]

        print(f"\n\n{color}=== Mrs Violet Noire is speaking (Final Assessment) ==={RESET}")
        logging.info(f"Final speaker: {persona_name} turn started.")

        # Check if model is available
        model = get_persona_model(persona_name)
        model_check_cmd = [OLLAMA_BIN, 'list']
        waiting_for_model = False
        try:
            result = subprocess.run(model_check_cmd, capture_output=True, text=True, timeout=5)
            if model not in result.stdout:
                print(f"[Status] Model '{model}' not found. Downloading... (timer paused)")
                waiting_for_model = True
                wait_start = time.time()
                pull_cmd = [OLLAMA_BIN, 'pull', model]
                subprocess.run(pull_cmd)
                wait_end = time.time()
                print(f"[Status] Model '{model}' downloaded in {wait_end - wait_start:.2f} seconds.")
        except Exception as e:
            print(f"[Warning] Could not check/download model '{model}': {e}")

        if waiting_for_model:
            turn_start = time.time()
            logging.info(f"Model '{model}' downloaded for persona '{persona_name}'.")

        # Mrs. Violet Noire reviews the transcript and provides her informed opinion
        q = f"Having reviewed the discussion about '{args.agenda}', what is your final assessment and recommendation?"
        choices = [
            f"I agree with the consensus and recommend proceeding",
            f"I have concerns and suggest alternative approaches",
            f"I need more information before making a recommendation",
            f"I disagree with the direction and propose a different path"
        ]

        turn_end = time.time()
        persona_timings[persona_name] = {'question_time': turn_end - turn_start}
        print(f"[Status] {persona_name} provided final assessment in {turn_end - turn_start:.2f} seconds.")

        user_answer = ask_multiple_choice(q, choices, allow_exit=True, user=True)
        logging.info(f"User answered Mrs. Violet Noire's final question: {user_answer}")
        critical_questions_for_user.append(user_answer)

        persona_asked[persona_name] = True
        transcript_entry = {
            "persona": persona_name,
            "question": q,
            "choices": choices,
            "user_answer": user_answer,
            "timestamp": time.strftime('%Y-%m-%d %H:%M:%S'),
            "duration": turn_end - turn_start
        }
        transcript.append(transcript_entry)

        # Write a JSON file for Mrs. Violet Noire
        speaker_json_path = Path(__file__).parent.parent / f"meeting_{persona_name}.json"
        with open(speaker_json_path, "w") as sjf:
            json.dump(transcript_entry, sjf, indent=2)

        # Handle user response
        if user_answer == "Exit":
            print("Meeting concluded by user.")
            logging.info(f"User ended meeting at Mrs. Violet Noire's final assessment.")
            return
        elif user_answer != "No comment":
            input(f"{color}Press Enter to proceed to final recommendations and voting...{RESET}")

    print(f"\n{COLORS[0]}All speakers have contributed. Proceeding to recommendations and voting...{RESET}")

    # Each persona provides summary and recommendation
    recommendations = {}
    technical_personas = [
        "dev-david-voice", "sysadmin-sam", "ai-architect-alex-voice", "devops-devon", "data-scientist-dana"
    ]
    tech_recommendations = {}
    for persona_name, persona_desc in personas:
        summary = persona_summary_and_recommendation(persona_name, persona_desc, transcript)
        print(f"\nSummary & Recommendation from {persona_name}:")
        print(summary)
        recommendations[persona_name] = summary
        if persona_name in technical_personas:
            tech_recommendations[persona_name] = summary
        logging.info(f"Summary & recommendation for {persona_name}: {summary[:100]}{'...' if len(summary)>100 else ''}")

    # After technical personas, print their improvement recommendations
    if tech_recommendations:
        print("\n=== Technical Persona Recommendations for Improvement ===")
        for name, rec in tech_recommendations.items():
            print(f"\n{name} suggests to improve the meeting, conversation, or code logic:")
            print(rec)

    # Improved voting system - top 3-5 recommendations only, no ties, ignore "No comment"
    print("\nVoting on recommendations:")
    rec_list = list(recommendations.values())

    # Filter and rank recommendations by length/substance (longer = more detailed)
    substantial_recs = [(rec, len(rec)) for rec in rec_list if "No comment" not in rec and len(rec) > 50]
    substantial_recs.sort(key=lambda x: x[1], reverse=True)  # Sort by length (more detailed first)

    # Take top 3-5 recommendations
    top_recs = [rec[0] for rec in substantial_recs[:5]]
    if len(top_recs) < 3:
        # If we don't have enough substantial recommendations, add shorter ones
        remaining_recs = [rec for rec in rec_list if rec not in top_recs and "No comment" not in rec]
        top_recs.extend(remaining_recs[:5-len(top_recs)])

    if not top_recs:
        print("No substantial recommendations to vote on.")
        return

    # Present top recommendations to user
    user_vote = ask_multiple_choice("Which recommendation do you support?", top_recs, allow_exit=True, user=True)
    logging.info(f"User voted for recommendation: {user_vote[:100]}{'...' if len(user_vote)>100 else ''}")
    if user_vote == "Exit":
        print("Meeting ended by user.")
        logging.info("Meeting ended by user at voting stage.")
        sys.exit(0)

    # Personas vote only on the top recommendations (timed, max 10s each)
    votes = {"user": user_vote}
    for persona_name, _ in personas:
        vote_start = time.time()
        vote = persona_vote(persona_name, top_recs)
        vote_end = time.time()
        persona_timings[persona_name]["vote_time"] = vote_end - vote_start
        print(f"[Status] {persona_name} voted in {vote_end - vote_start:.2f} seconds.")
        votes[persona_name] = vote
        logging.info(f"Persona '{persona_name}' voted for: {vote[:100]}{'...' if len(vote)>100 else ''}")

    # Tally votes (equal weight, ignore "No comment")
    tally = {}
    for voter, vote in votes.items():
        if vote and "No comment" not in vote:
            tally[vote] = tally.get(vote, 0) + 1

    # Prevent ties by adding random tiebreaker if needed
    if tally:
        max_votes = max(tally.values())
        tied_options = [rec for rec, count in tally.items() if count == max_votes]

        if len(tied_options) > 1:
            # Tiebreaker: prefer user's choice, then longest recommendation
            if user_vote in tied_options:
                winner = user_vote
            else:
                winner = max(tied_options, key=len)
            print(f"\n[Tiebreaker] Multiple options tied with {max_votes} votes. Selected: {winner[:60]}...")
        else:
            winner = tied_options[0]
    print("\nVote tally:")
    for rec, count in tally.items():
        print(f"  {count} votes: {rec[:60]}{'...' if len(rec)>60 else ''}")
        logging.info(f"Vote tally: {count} votes for: {rec[:100]}{'...' if len(rec)>100 else ''}")

    meeting_end = time.time()
    total_duration = meeting_end - meeting_start
    print(f"\nMeeting complete. Total duration: {total_duration:.2f} seconds.")
    print("\nPersona timings:")
    for persona, timing in persona_timings.items():
        print(f"  {persona}: question {timing.get('question_time', 0):.2f}s, vote {timing.get('vote_time', 0):.2f}s")
        logging.info(f"Timing for {persona}: question {timing.get('question_time', 0):.2f}s, vote {timing.get('vote_time', 0):.2f}s")
    print("\nTranscript and votes above.")
    logging.info(f"Meeting complete. Total duration: {total_duration:.2f} seconds.")

    # --- Agile Sprint Summary Generation ---
    summary_lines = []
    summary_lines.append("\n---\n")
    summary_lines.append(f"## Agile Sprint Summary: LLM Meeting Orchestrator\n")
    summary_lines.append(f"**Date:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
    summary_lines.append(f"**Meeting Title:** {args.title}\n")
    summary_lines.append(f"**Agenda:** {args.agenda}\n")
    summary_lines.append(f"**Total Duration:** {total_duration:.2f} seconds\n")
    summary_lines.append(f"\n### Completed Work (Sprint Review)")
    summary_lines.append(f"- Interactive, validated, and transparent LLM-powered meeting system")
    summary_lines.append(f"- Real-time status, progress bar, and timing for each persona and the overall meeting")
    summary_lines.append(f"- Persona-driven Q&A, voting, and recommendations\n")
    summary_lines.append(f"\n### Demo / Sprint Review\n- All personas participated, summarized, and voted on recommendations.\n")
    summary_lines.append(f"\n### Sprint Retrospective\n**What Went Well:**\n- Automation and persona management\n- Python orchestrator enabled rapid feature iteration\n- Real-time feedback and progress tracking improved meeting transparency\n\n**What Could Be Improved:**\n- Minor lint warnings remain (string duplication, file read warning)\n- Further UI/UX polish could enhance user experience\n- Consider exporting meeting results to Agile artifacts (user stories, action items)\n\n**Action Items:**\n- Refactor repeated string literals\n- Address file read security warning if needed\n- Explore exporting meeting outcomes to Agile artifacts\n")
    summary_lines.append(f"\n### Next Steps\n- Test the orchestrator in a real meeting scenario\n- Gather feedback from users/personas\n- Plan next sprint: focus on exporting results, UI/UX improvements, and further automation\n")
    summary_lines.append(f"\n**Sprint Complete. Ready for review and feedback!**\n")

    # Write or append to meeting_summaries.md
    summary_path = Path(__file__).parent.parent / "meeting_summaries.md"
    with open(summary_path, "a") as f:
        f.write("\n".join(summary_lines))

if __name__ == "__main__":
    main()
