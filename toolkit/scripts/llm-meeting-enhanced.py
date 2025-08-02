#!/usr/bin/env python3
"""
Enhanced LLM Meeting Orchestrator with Technical Improvements
Based on technical team recommendations:
- Retry logic for LLM timeouts
- Model caching system
- Performance monitoring dashboard
- Graceful degradation for slow responses
- Health checks for system components
"""

import argparse
import json
import logging
import os
import random
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import threading
import hashlib
from datetime import datetime, timedelta

# Configuration
PERSONA_DIR = Path(__file__).parent.parent / "prompts"

# Constants
OLLAMA_BIN = "ollama"
OLLAMA_MODEL = "llama3.2:latest"
EXIT_COMMAND = "Exit"
NO_COMMENT = "No comment"
DEFAULT_TIMEOUT = 30
MAX_RETRIES = 3
CACHE_TTL_HOURS = 24
FINAL_PERSONA = "Mrs. Violet Noire"  # Define constant for repeated literal

# File paths
MODEL_CACHE_FILE = Path(__file__).parent / "model_cache.json"
PERFORMANCE_LOG_FILE = Path(__file__).parent / "performance_metrics.log"

# Cache configuration
CACHE_DURATION = timedelta(hours=CACHE_TTL_HOURS)
LLAMA_MODEL = "llama3.1"
CODELLAMA_MODEL = "codellama"

PERSONA_MODEL_MAP = {
    # Technical/engineering personas
    "dev-david-voice": CODELLAMA_MODEL,
    "sysadmin-sam": CODELLAMA_MODEL,
    "ai-architect-alex-voice": LLAMA_MODEL,
    "devops-devon": CODELLAMA_MODEL,
    "data-scientist-dana": LLAMA_MODEL,
    # Security personas
    "secanalyst-sage": LLAMA_MODEL,
    "redteam-ruby": LLAMA_MODEL,
    "blueteam-ben": LLAMA_MODEL,
    # Business/leadership personas
    "leader-larry-voice": LLAMA_MODEL,
    "strategy-steve-voice": LLAMA_MODEL,
    "finance-fred-voice": LLAMA_MODEL,
    "pm-penny-voice": LLAMA_MODEL,
    # Legal/privacy/HR personas
    "legal-louise": LLAMA_MODEL,
    "privacy-pat": LLAMA_MODEL,
    "hr-hannah-voice": LLAMA_MODEL,
    # Creative/UX personas
    "designer-debbie-voice": LLAMA_MODEL,
}

OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1")
OLLAMA_BIN = os.environ.get("OLLAMA_BIN", "ollama")

# Enhanced Configuration
DEFAULT_TIMEOUT = 10
MAX_RETRIES = 3
CACHE_DURATION = timedelta(hours=1)
PERFORMANCE_LOG_FILE = Path(__file__).parent / "performance_metrics.log"
MODEL_CACHE_FILE = Path(__file__).parent / "model_cache.json"

# Constants for consistent messaging
NO_COMMENT = "No comment"
EXIT_COMMAND = "Exit"

# Performance Monitoring Class
class PerformanceMonitor:
    def __init__(self):
        self.metrics = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'retry_count': 0,
            'average_response_time': 0.0,
            'persona_performance': {},
            'model_performance': {},
            'cache_hits': 0,
            'cache_misses': 0
        }
        self.response_times = []

    def log_request(self, persona: str, model: str, duration: float, success: bool, retries: int = 0):
        self.metrics['total_requests'] += 1
        if success:
            self.metrics['successful_requests'] += 1
        else:
            self.metrics['failed_requests'] += 1

        self.metrics['retry_count'] += retries
        self.response_times.append(duration)
        self.metrics['average_response_time'] = sum(self.response_times) / len(self.response_times)

        # Track per-persona performance
        if persona not in self.metrics['persona_performance']:
            self.metrics['persona_performance'][persona] = {
                'requests': 0, 'avg_time': 0.0, 'success_rate': 0.0, 'times': []
            }

        persona_stats = self.metrics['persona_performance'][persona]
        persona_stats['requests'] += 1
        persona_stats['times'].append(duration)
        persona_stats['avg_time'] = sum(persona_stats['times']) / len(persona_stats['times'])
        persona_stats['success_rate'] = (persona_stats.get('successes', 0) + (1 if success else 0)) / persona_stats['requests']
        if success:
            persona_stats['successes'] = persona_stats.get('successes', 0) + 1

        # Track per-model performance
        if model not in self.metrics['model_performance']:
            self.metrics['model_performance'][model] = {
                'requests': 0, 'avg_time': 0.0, 'success_rate': 0.0, 'times': []
            }

        model_stats = self.metrics['model_performance'][model]
        model_stats['requests'] += 1
        model_stats['times'].append(duration)
        model_stats['avg_time'] = sum(model_stats['times']) / len(model_stats['times'])
        model_stats['success_rate'] = (model_stats.get('successes', 0) + (1 if success else 0)) / model_stats['requests']
        if success:
            model_stats['successes'] = model_stats.get('successes', 0) + 1

    def log_cache_hit(self):
        self.metrics['cache_hits'] += 1

    def log_cache_miss(self):
        self.metrics['cache_misses'] += 1

    def start_monitoring(self):
        """Start performance monitoring session."""
        logging.info("Performance monitoring started")

    def save_metrics(self):
        """Save performance metrics to file."""
        try:
            with open(PERFORMANCE_LOG_FILE, 'a') as f:
                f.write(f"\n=== Performance Session {datetime.now().isoformat()} ===\n")
                f.write(json.dumps(self.metrics, indent=2))
                f.write("\n" + "="*50 + "\n")
            logging.info(f"Performance metrics saved to {PERFORMANCE_LOG_FILE}")
        except Exception as e:
            logging.error(f"Failed to save performance metrics: {e}")

    def get_report(self) -> str:
        cache_total = self.metrics['cache_hits'] + self.metrics['cache_misses']
        cache_hit_rate = (self.metrics['cache_hits'] / cache_total * 100) if cache_total > 0 else 0

        report = f"""
=== Performance Monitoring Report ===
Total Requests: {self.metrics['total_requests']}
Success Rate: {(self.metrics['successful_requests'] / max(self.metrics['total_requests'], 1) * 100):.1f}%
Average Response Time: {self.metrics['average_response_time']:.2f}s
Total Retries: {self.metrics['retry_count']}
Cache Hit Rate: {cache_hit_rate:.1f}%

=== Top Performing Personas ==="""

        # Sort personas by success rate and response time
        personas = sorted(
            self.metrics['persona_performance'].items(),
            key=lambda x: (x[1]['success_rate'], -x[1]['avg_time']),
            reverse=True
        )

        for persona, stats in personas[:5]:
            report += f"\n{persona}: {stats['success_rate']*100:.1f}% success, {stats['avg_time']:.2f}s avg"

        return report

# Model Cache System
class ModelCache:
    def __init__(self):
        self.cache_file = MODEL_CACHE_FILE
        self.cache = self._load_cache()

    def _load_cache(self) -> dict:
        if self.cache_file.exists():
            try:
                with open(self.cache_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, FileNotFoundError):
                return {}
        return {}

    def _save_cache(self):
        with open(self.cache_file, 'w') as f:
            json.dump(self.cache, f, indent=2)

    def _get_cache_key(self, prompt: str, model: str) -> str:
        return hashlib.md5(f"{prompt}_{model}".encode()).hexdigest()

    def get(self, prompt: str, model: str) -> Optional[str]:
        key = self._get_cache_key(prompt, model)
        if key in self.cache:
            entry = self.cache[key]
            timestamp = datetime.fromisoformat(entry['timestamp'])
            if datetime.now() - timestamp < CACHE_DURATION:
                return entry['response']
            else:
                # Cache expired
                del self.cache[key]
                self._save_cache()
        return None

    def set(self, prompt: str, model: str, response: str):
        key = self._get_cache_key(prompt, model)
        self.cache[key] = {
            'response': response,
            'timestamp': datetime.now().isoformat()
        }
        self._save_cache()

    def cache_model(self, model: str):
        """Mark model as cached/loaded."""
        logging.info(f"Model {model} marked as cached")

# Global instances
performance_monitor = PerformanceMonitor()
model_cache = ModelCache()

# Enhanced LLM Generation with Retry Logic
def ollama_generate_with_retry(prompt: str, model: str = OLLAMA_MODEL, timeout: int = DEFAULT_TIMEOUT, max_retries: int = MAX_RETRIES) -> str:
    """
    Enhanced ollama generation with retry logic, caching, and performance monitoring.
    """
    start_time = time.time()

    # Check cache first
    cached_response = model_cache.get(prompt, model)
    if cached_response:
        performance_monitor.log_cache_hit()
        performance_monitor.log_request("cached", model, time.time() - start_time, True, 0)
        return cached_response

    performance_monitor.log_cache_miss()

    for attempt in range(max_retries + 1):
        try:
            result = subprocess.run([
                OLLAMA_BIN, "run", model, prompt
            ], capture_output=True, text=True, timeout=timeout)

            if result.returncode == 0 and result.stdout.strip():
                response = result.stdout.strip()
                duration = time.time() - start_time

                # Cache successful response
                model_cache.set(prompt, model, response)

                # Log performance
                performance_monitor.log_request("llm", model, duration, True, attempt)

                if attempt > 0:
                    logging.info(f"Successful retry {attempt} for model {model}")

                return response
            else:
                logging.warning(f"LLM returned error: {result.stderr}")

        except subprocess.TimeoutExpired:
            logging.warning(f"Timeout on attempt {attempt + 1} for model {model}")

        except Exception as e:
            logging.error(f"Error on attempt {attempt + 1} for model {model}: {e}")

        # Wait before retry (exponential backoff)
        if attempt < max_retries:
            wait_time = (2 ** attempt) + random.uniform(0, 1)
            logging.info(f"Retrying in {wait_time:.1f} seconds...")
            time.sleep(wait_time)

    # All retries failed
    duration = time.time() - start_time
    performance_monitor.log_request("llm", model, duration, False, max_retries)
    logging.error(f"All {max_retries + 1} attempts failed for model {model}")
    return "Response failed after multiple retries."

# Health Check System
class HealthChecker:
    @staticmethod
    def check_ollama_service() -> bool:
        """Check if Ollama service is running"""
        try:
            result = subprocess.run([OLLAMA_BIN, "list"], capture_output=True, timeout=5)
            return result.returncode == 0
        except Exception:
            return False

    @staticmethod
    def check_models_available() -> Dict[str, bool]:
        """Check which models are available"""
        model_status = {}
        try:
            result = subprocess.run([OLLAMA_BIN, "list"], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                available_models = result.stdout
                for model in set(PERSONA_MODEL_MAP.values()):
                    model_status[model] = model in available_models
            else:
                # If command failed, assume all models unavailable
                for model in set(PERSONA_MODEL_MAP.values()):
                    model_status[model] = False
        except Exception as e:
            logging.error(f"Health check failed: {e}")
            for model in set(PERSONA_MODEL_MAP.values()):
                model_status[model] = False

        return model_status

    @staticmethod
    def get_system_health() -> Dict:
        """Get comprehensive system health status"""
        return {
            'ollama_service': HealthChecker.check_ollama_service(),
            'models': HealthChecker.check_models_available(),
            'cache_status': model_cache.cache_file.exists(),
            'performance_log': PERFORMANCE_LOG_FILE.exists(),
            'timestamp': datetime.now().isoformat()
        }

    def check_all(self) -> bool:
        """Check all health indicators"""
        health = self.get_system_health()
        return health['ollama_service'] and any(health['models'].values())

# Utility functions
def get_persona_model(persona_name: str) -> str:
    return PERSONA_MODEL_MAP.get(persona_name, OLLAMA_MODEL)

def get_persona_files() -> List[Path]:
    return sorted(PERSONA_DIR.glob("*.md"))

def read_persona(persona_file: Path) -> str:
    if not persona_file.is_file():
        return f"Persona file {persona_file} not found."
    try:
        return persona_file.read_text(encoding='utf-8')
    except Exception as e:
        return f"Error reading persona file {persona_file}: {e}"

def print_progress_bar(iteration: int, total: int, prefix: str = '', suffix: str = '', decimals: int = 1, length: int = 40, fill: str = '█', print_end: str = "\r") -> None:
    """Call in a loop to create terminal progress bar"""
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filled_length = int(length * iteration // total)
    bar = fill * filled_length + '-' * (length - filled_length)
    print(f'{prefix} |{bar}| {percent}% {suffix}', end=print_end)
    if iteration == total:
        print()

def ask_multiple_choice(question: str, choices: List[str], allow_exit: bool = True) -> str:
    """Enhanced multiple choice with better error handling"""
    if allow_exit and EXIT_COMMAND not in choices:
        choices.append(EXIT_COMMAND)

    print(f"\n{question}")
    for i, choice in enumerate(choices, 1):
        print(f"  {i}. {choice}")

    while True:
        try:
            choice_input = input("Select an option: ").strip()
            choice_num = int(choice_input)

            if 1 <= choice_num <= len(choices):
                selected = choices[choice_num - 1]
                logging.info(f"User selected option {choice_num}: {selected}")
                return selected
            else:
                print(f"Please enter a number between 1 and {len(choices)}.")

        except ValueError:
            print("Please enter a valid number.")
        except KeyboardInterrupt:
            print("\nExiting...")
            return EXIT_COMMAND

def persona_ask_question(persona_name: str, persona_desc: str, context: str, to_user: bool = True) -> Tuple[str, List[str]]:
    """Enhanced persona question generation with performance monitoring"""
    model = get_persona_model(persona_name)

    if to_user:
        prompt = f"""
Based on this persona description:
{persona_desc}

And this meeting context:
{context}

Generate a thoughtful question that this persona would ask the user, along with 3-4 multiple choice options.

Format your response as:
QUESTION: [question here]
OPTIONS: [option1] | [option2] | [option3] | [option4]
"""
    else:
        prompt = f"""
Based on this persona description:
{persona_desc}

And this meeting context:
{context}

Generate a discussion point or question this persona would raise with other team members.

Format your response as:
QUESTION: [question here]
OPTIONS: [option1] | [option2] | [option3]
"""

    response_start = time.time()
    response = ollama_generate_with_retry(prompt, model=model)
    response_time = time.time() - response_start

    print(f"[Timing] LLM response time: {response_time:.2f} seconds.")
    if response_time > 5:
        print(f"[Warning] LLM response for {persona_name} took longer than 5 seconds.")

    # Parse response
    try:
        lines = response.strip().split('\n')
        question = ""
        options = []

        for line in lines:
            if line.startswith("QUESTION:"):
                question = line[9:].strip()
            elif line.startswith("OPTIONS:"):
                options = [opt.strip() for opt in line[8:].split('|')]

        if not question:
            question = f"What are your thoughts on the current topic from {persona_name}'s perspective?"

        if not options:
            options = ["Agree with the proposal", "Need more information", NO_COMMENT]

        return question, options

    except Exception as e:
        logging.error(f"Error parsing persona response: {e}")
        return f"What are your thoughts on this topic from {persona_name}'s perspective?", ["Agree", "Disagree", NO_COMMENT]

# Continue with additional enhanced functions...
def persona_summary_and_recommendation(persona_name: str, persona_desc: str, transcript: List[Dict]) -> str:
    """Enhanced summary generation with performance monitoring"""
    model = get_persona_model(persona_name)

    # Prepare transcript summary
    transcript_summary = ""
    for entry in transcript[-5:]:  # Last 5 entries for context
        transcript_summary += f"{entry['persona']}: {entry['question']} -> {entry['user_answer']}\n"

    prompt = f"""
Based on this persona:
{persona_desc}

And this meeting transcript:
{transcript_summary}

Provide a brief summary of your participation and a clear path forward recommendation (2-3 sentences max).
"""

    return ollama_generate_with_retry(prompt, model=model, timeout=15)

def persona_vote(persona_name: str, recommendations: List[str]) -> str:
    """Enhanced voting with performance monitoring"""
    model = get_persona_model(persona_name)

    rec_list = "\n".join([f"{i+1}. {rec[:100]}..." for i, rec in enumerate(recommendations)])

    prompt = f"""
As {persona_name}, choose the best recommendation from these options:

{rec_list}

Respond with just the number of your choice (1-{len(recommendations)}).
"""

    try:
        response = ollama_generate_with_retry(prompt, model=model, timeout=10)
        choice_num = int(response.strip())
        if 1 <= choice_num <= len(recommendations):
            return recommendations[choice_num - 1]
    except (ValueError, IndexError):
        pass

    # Fallback to first recommendation
    return recommendations[0] if recommendations else NO_COMMENT

def save_performance_report():
    """Save performance report to file"""
    report = performance_monitor.get_report()
    with open(PERFORMANCE_LOG_FILE, 'a') as f:
        f.write(f"\n=== Performance Report {datetime.now().isoformat()} ===\n")
        f.write(report)
        f.write("\n" + "="*50 + "\n")

def main():
    """Enhanced main function with comprehensive monitoring and error handling"""
    parser = argparse.ArgumentParser(description="Enhanced LLM Meeting Orchestrator")
    parser.add_argument("--title", help="Meeting title")
    parser.add_argument("--agenda", help="Meeting agenda")
    parser.add_argument("--health-check", action="store_true", help="Run system health check")
    parser.add_argument("--performance-report", action="store_true", help="Show performance report")
    args = parser.parse_args()

    # Set up enhanced logging
    log_file = Path(__file__).parent / "meetingdebug_enhanced.log"
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

    if args.health_check:
        health = HealthChecker.get_system_health()
        print("=== System Health Check ===")
        print(f"Ollama Service: {'✅' if health['ollama_service'] else '❌'}")
        print("Model Availability:")
        for model, available in health['models'].items():
            print(f"  {model}: {'✅' if available else '❌'}")
        print(f"Cache System: {'✅' if health['cache_status'] else '❌'}")
        print(f"Performance Logging: {'✅' if health['performance_log'] else '❌'}")
        return

    if args.performance_report:
        print(performance_monitor.get_report())
        return

    if not args.title or not args.agenda:
        parser.error("--title and --agenda are required for running meetings")

    # Start enhanced meeting
    meeting_start = time.time()
    logging.info("=== Enhanced LLM Meeting Orchestrator started ===")
    logging.info(f"Meeting: {args.title} | Agenda: {args.agenda}")

    # Run initial health check
    health = HealthChecker.get_system_health()
    if not health['ollama_service']:
        print("❌ Ollama service is not running. Please start Ollama first.")
        sys.exit(1)

    # Check model availability
    unavailable_models = [model for model, available in health['models'].items() if not available]
    if unavailable_models:
        print(f"⚠️  Warning: These models are not available: {', '.join(unavailable_models)}")
        print("The system will attempt to download them automatically during the meeting.")

    print(f"🧑‍💼 Enhanced LLM Meeting: {args.title}")
    print(f"📝 Agenda: {args.agenda}")
    print("----------------------------------------")
    print("[Meeting Status] Enhanced meeting system with retry logic, caching, and performance monitoring active.")

    try:
        # Initialize enhanced meeting orchestrator
        orchestrator = EnhancedMeetingOrchestrator(args.title, args.agenda)
        orchestrator.run_meeting()

        meeting_duration = time.time() - meeting_start
        logging.info(f"Meeting completed successfully in {meeting_duration:.2f} seconds")

        # Save final performance report
        save_performance_report()

        print("\n✅ Meeting completed successfully!")
        print(f"⏱️  Total duration: {meeting_duration:.2f} seconds")
        print(f"📊 Performance report saved to {PERFORMANCE_LOG_FILE}")

    except KeyboardInterrupt:
        print("\n\n❌ Meeting interrupted by user.")
        logging.info("Meeting interrupted by user")
    except Exception as e:
        logging.error(f"Meeting failed: {str(e)}")
        print(f"\n❌ Meeting failed: {str(e)}")
        sys.exit(1)

# Enhanced Meeting Orchestrator Class
class EnhancedMeetingOrchestrator:
    """Enhanced meeting orchestrator with comprehensive monitoring and reliability improvements."""

    def __init__(self, title: str, agenda: str):
        self.title = title
        self.agenda = agenda
        self.logger = logging.getLogger(__name__)
        self.meeting_memory = {}
        self.user_context = {}

        # Load personas
        self.personas = self.load_personas()

        # Initialize monitoring systems
        self.performance_monitor = None
        self.model_cache = None
        self.health_checker = None

    def load_personas(self) -> Dict[str, Dict]:
        """Load all persona configurations."""
        personas = {}
        persona_files = get_persona_files()

        for persona_file in persona_files:
            persona_name = persona_file.stem.replace('-', ' ').title()
            personas[persona_name] = {
                "content": read_persona(persona_file),
                "model": get_persona_model(persona_name),
                "file": persona_file
            }

        self.logger.info(f"Loaded {len(personas)} personas: {list(personas.keys())}")
        return personas

    def ask_llm_with_retry(self, prompt: str, model: str, max_retries: int = MAX_RETRIES, timeout: int = DEFAULT_TIMEOUT) -> str:
        """Wrapper for LLM generation with retry logic."""
        return ollama_generate_with_retry(prompt, model, timeout, max_retries)

    def run_meeting(self) -> None:
        """Run the complete enhanced meeting with all monitoring systems."""
        try:
            self.performance_monitor = PerformanceMonitor()
            self.model_cache = ModelCache()
            self.health_checker = HealthChecker()

            # Start performance monitoring
            self.performance_monitor.start_monitoring()

            # Initialize models in cache
            self.initialize_models()

            # Run startup health check
            if not self.health_checker.check_all():
                self.logger.warning("Some health checks failed during startup")

            # Enhanced user initialization
            self.initial_user_questions()

            # Main meeting phases
            self.run_pre_meeting_phase()
            self.run_discussion_phase()
            self.run_conclusion_phase()

            self.logger.info("Meeting completed successfully")

        except Exception as e:
            self.logger.error(f"Meeting failed: {str(e)}")
            print(f"\nError: Meeting failed - {str(e)}")
            raise
        finally:
            # Save performance metrics
            if hasattr(self, 'performance_monitor'):
                self.performance_monitor.save_metrics()

    def initialize_models(self) -> None:
        """Pre-load models for faster response times."""
        self.logger.info("Initializing models...")

        try:
            # Pre-warm primary models
            for model in ["llama3.2:latest", "codegemma:latest", "phi3:latest"]:
                self.logger.info(f"Pre-loading model: {model}")
                try:
                    # Quick test query to load model
                    self.ask_llm_with_retry("Test", model, max_retries=1, timeout=30)
                    self.model_cache.cache_model(model)
                    self.logger.info(f"Model {model} loaded successfully")
                except Exception as e:
                    self.logger.warning(f"Failed to pre-load model {model}: {str(e)}")

        except Exception as e:
            self.logger.error(f"Model initialization failed: {str(e)}")

    def initial_user_questions(self) -> None:
        """Enhanced initial user interaction with more comprehensive questions."""
        self.logger.info("Starting enhanced user initialization")

        questions = [
            {
                "prompt": "What type of content or project would you like to discuss today?",
                "options": [
                    "Book review or literary analysis",
                    "Creative writing project",
                    "Website or technical development",
                    "Business strategy or planning",
                    "General brainstorming session"
                ]
            },
            {
                "prompt": "What's your primary goal for this meeting?",
                "options": [
                    "Generate new ideas",
                    "Solve a specific problem",
                    "Get feedback on existing work",
                    "Plan next steps for a project",
                    "Explore different perspectives"
                ]
            },
            {
                "prompt": "How much technical detail would you like in the discussion?",
                "options": [
                    "High-level overview only",
                    "Moderate technical depth",
                    "Deep technical analysis",
                    "Mixed levels as needed"
                ]
            }
        ]

        self.user_context = {}
        for i, question in enumerate(questions):
            self.logger.info(f"Asking user question {i+1}: {question['prompt']}")
            answer = ask_multiple_choice(question["prompt"], question["options"])
            self.user_context[f"question_{i+1}"] = answer
            self.logger.info(f"User answered: {answer}")

        # Additional open-ended question
        print("\nPlease provide any additional context or specific topics you'd like to focus on:")
        additional_context = input("> ").strip()
        if additional_context:
            self.user_context["additional_context"] = additional_context
            self.logger.info(f"Additional context: {additional_context}")

    def run_pre_meeting_phase(self) -> None:
        """Enhanced pre-meeting preparation with context distribution."""
        self.logger.info("Starting pre-meeting phase")

        # Prepare context for personas
        context_summary = self.prepare_context_summary()

        # Each persona prepares their approach
        for persona_name in self.personas.keys():
            self.logger.info(f"Pre-meeting preparation for {persona_name}")

            try:
                prep_response = self.ask_llm_with_retry(
                    f"Based on this meeting context: {context_summary}\n\n"
                    f"Prepare your approach as {persona_name}. What key points will you focus on? "
                    f"Keep this brief (2-3 sentences).",
                    self.personas[persona_name]["model"]
                )

                self.meeting_memory[persona_name] = {
                    "preparation": prep_response,
                    "responses": []
                }

                self.logger.info(f"{persona_name} preparation complete")

            except Exception as e:
                self.logger.error(f"Pre-meeting preparation failed for {persona_name}: {str(e)}")

    def prepare_context_summary(self) -> str:
        """Create a summary of user context for persona preparation."""
        summary_parts = []

        for key, value in self.user_context.items():
            if key.startswith("question_"):
                summary_parts.append(f"User {key.replace('_', ' ')}: {value}")
            elif key == "additional_context":
                summary_parts.append(f"Additional context: {value}")

        return " | ".join(summary_parts)

    def run_discussion_phase(self) -> None:
        """Enhanced discussion phase with improved flow and memory."""
        self.logger.info("Starting discussion phase")

        round_count = 0
        max_rounds = 3

        while round_count < max_rounds:
            round_count += 1
            self.logger.info(f"Starting discussion round {round_count}")

            print(f"\n{'='*60}")
            print(f"DISCUSSION ROUND {round_count}")
            print(f"{'='*60}")

            # All personas except Mrs. Violet Noire participate
            discussion_personas = [name for name in self.personas.keys() if name != FINAL_PERSONA]

            for persona_name in discussion_personas:
                self.logger.info(f"Getting response from {persona_name}")

                try:
                    # Build context from previous rounds
                    context = self.build_discussion_context(persona_name, round_count)

                    response = self.ask_llm_with_retry(
                        context,
                        self.personas[persona_name]["model"]
                    )

                    # Store response
                    self.meeting_memory[persona_name]["responses"].append({
                        "round": round_count,
                        "response": response
                    })

                    print(f"\n{persona_name}:")
                    print("-" * 40)
                    print(response)

                    self.logger.info(f"{persona_name} responded successfully")

                except Exception as e:
                    self.logger.error(f"Failed to get response from {persona_name}: {str(e)}")
                    print(f"\n{persona_name}: [Unable to respond - technical issue]")

            # Check if we should continue
            if round_count < max_rounds:
                continue_discussion = ask_multiple_choice(
                    f"Continue with round {round_count + 1}?",
                    ["Yes, continue discussion", "No, move to conclusion"]
                )

                if "No" in continue_discussion:
                    break

    def build_discussion_context(self, persona_name: str, round_count: int) -> str:
        """Build contextual prompt for persona based on meeting history."""
        context_parts = []

        # Add user context
        context_parts.append(f"Meeting context: {self.prepare_context_summary()}")

        # Add persona preparation
        if persona_name in self.meeting_memory and "preparation" in self.meeting_memory[persona_name]:
            context_parts.append(f"Your preparation: {self.meeting_memory[persona_name]['preparation']}")

        # Add previous round responses
        if round_count > 1:
            context_parts.append("\nPrevious discussion points:")
            for other_persona in self.meeting_memory:
                if other_persona != persona_name and "responses" in self.meeting_memory[other_persona]:
                    for response_data in self.meeting_memory[other_persona]["responses"]:
                        if response_data["round"] < round_count:
                            context_parts.append(f"{other_persona} (Round {response_data['round']}): {response_data['response'][:200]}...")

        # Add persona-specific prompt
        persona_prompt = f"\nAs {persona_name}, provide your perspective on the discussion. "

        if round_count == 1:
            persona_prompt += "Share your initial thoughts and key points."
        else:
            persona_prompt += "Build on the previous discussion and add new insights."

        context_parts.append(persona_prompt)

        return "\n".join(context_parts)

    def run_conclusion_phase(self) -> None:
        """Enhanced conclusion with Mrs. Violet Noire's comprehensive review."""
        self.logger.info("Starting conclusion phase")

        print(f"\n{'='*60}")
        print("CONCLUSION PHASE")
        print(f"{'='*60}")

        # Mrs. Violet Noire reviews everything and provides final thoughts
        try:
            # Build comprehensive context for final review
            final_context = self.build_final_context()

            self.logger.info(f"Getting final review from {FINAL_PERSONA}")

            final_response = self.ask_llm_with_retry(
                final_context,
                self.personas[FINAL_PERSONA]["model"]
            )

            print(f"\n{FINAL_PERSONA} (Final Review):")
            print("-" * 50)
            print(final_response)

            # Store final response
            if FINAL_PERSONA not in self.meeting_memory:
                self.meeting_memory[FINAL_PERSONA] = {"responses": []}

            self.meeting_memory[FINAL_PERSONA]["responses"].append({
                "type": "final_review",
                "response": final_response
            })

            self.logger.info("Final review completed successfully")

        except Exception as e:
            self.logger.error(f"Final review failed: {str(e)}")
            print(f"\n{FINAL_PERSONA}: [Unable to provide final review - technical issue]")

        # Enhanced voting with top recommendations
        self.conduct_enhanced_voting()

    def build_final_context(self) -> str:
        """Build comprehensive context for Mrs. Violet Noire's final review."""
        context_parts = []

        # Meeting overview
        context_parts.append("MEETING SUMMARY FOR FINAL REVIEW")
        context_parts.append(f"Meeting context: {self.prepare_context_summary()}")

        # All persona responses
        context_parts.append("\nCOMPLETE DISCUSSION:")
        for persona_name, persona_data in self.meeting_memory.items():
            if persona_name != FINAL_PERSONA and "responses" in persona_data:
                context_parts.append(f"\n{persona_name}:")
                for response_data in persona_data["responses"]:
                    if "round" in response_data:
                        context_parts.append(f"Round {response_data['round']}: {response_data['response']}")
                    else:
                        context_parts.append(response_data["response"])

        # Final review prompt
        context_parts.append(f"\nAs {FINAL_PERSONA}, provide a comprehensive final review. "
                           "Synthesize the discussion, identify key themes, and offer your "
                           "refined perspective. What are the most important takeaways?")

        return "\n".join(context_parts)

    def conduct_enhanced_voting(self) -> None:
        """Enhanced voting system with top 3-5 actionable recommendations."""
        self.logger.info("Starting enhanced voting phase")

        print(f"\n{'='*60}")
        print("ACTIONABLE RECOMMENDATIONS")
        print(f"{'='*60}")

        try:
            # Generate top recommendations
            recommendations_context = self.build_recommendations_context()

            recommendations_response = self.ask_llm_with_retry(
                recommendations_context,
                "llama3.2:latest"
            )

            print("\nTop Actionable Recommendations:")
            print("-" * 40)
            print(recommendations_response)

            self.logger.info("Enhanced voting completed successfully")

        except Exception as e:
            self.logger.error(f"Enhanced voting failed: {str(e)}")
            print("\nUnable to generate recommendations - technical issue")

    def build_recommendations_context(self) -> str:
        """Build context for generating actionable recommendations."""
        context_parts = []

        context_parts.append("Based on this complete meeting discussion, generate 3-5 specific, "
                           "actionable recommendations. Each recommendation should be:")
        context_parts.append("1. Concrete and implementable")
        context_parts.append("2. Based on the discussion points raised")
        context_parts.append("3. Relevant to the user's stated goals")
        context_parts.append("")

        # Add meeting context
        context_parts.append(f"User Goals: {self.prepare_context_summary()}")
        context_parts.append("")

        # Add key discussion points
        context_parts.append("Key Discussion Points:")
        for persona_name, persona_data in self.meeting_memory.items():
            if "responses" in persona_data:
                for response_data in persona_data["responses"]:
                    if "response" in response_data:
                        # Extract key points (first sentence or two)
                        response_text = response_data["response"]
                        sentences = response_text.split(". ")
                        key_point = ". ".join(sentences[:2]) + "."
                        context_parts.append(f"- {persona_name}: {key_point}")

        context_parts.append("\nFormat each recommendation as:")
        context_parts.append("Recommendation N: [Clear action item]")
        context_parts.append("Rationale: [Why this is important based on the discussion]")

        return "\n".join(context_parts)

if __name__ == "__main__":
    main()
