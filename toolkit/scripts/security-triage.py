#!/usr/bin/env python3
"""
Security Triage Multi-Agent System
Integrates with our enhanced meeting orchestrator for vulnerability analysis
Using existing infrastructure instead of external llm-conversation
"""

import argparse
import json
import logging
import subprocess
import sys
import yaml
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Configuration
SCRIPT_DIR = Path(__file__).parent
CONFIG_DIR = SCRIPT_DIR.parent / "config"
PERSONAS_FILE = CONFIG_DIR / "security-personas.yaml"
TRIAGE_OUTPUT_DIR = SCRIPT_DIR.parent.parent / "security-triage"
ENHANCED_MEETING_SCRIPT = SCRIPT_DIR / "llm-meeting-enhanced.py"

def setup_logging():
    """Setup logging for security triage operations."""
    log_file = SCRIPT_DIR / "security-triage.log"
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

def check_dependencies():
    """Check if required dependencies are available."""
    logger = logging.getLogger(__name__)

    # Check for Ollama
    try:
        result = subprocess.run(['ollama', 'list'],
                              capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            logger.error("❌ Ollama not running. Start with: ollama serve")
            return False
        logger.info("✅ Ollama service available")
    except (subprocess.TimeoutExpired, FileNotFoundError):
        logger.error("❌ Ollama not found. Install from: https://ollama.com")
        return False

    # Check for enhanced meeting orchestrator
    if not ENHANCED_MEETING_SCRIPT.exists():
        logger.error("❌ Enhanced meeting orchestrator not found")
        return False

    logger.info("✅ Enhanced meeting orchestrator available")
    return True

def create_vulnerability_input(vulnerabilities: List[Dict]) -> str:
    """Convert vulnerability data to markdown format for analysis."""
    content = ["# Security Vulnerability Analysis Request\n"]

    content.append("## Executive Summary")
    content.append(f"Analysis of {len(vulnerabilities)} security findings requiring triage and prioritization.\n")

    content.append("## Vulnerability Details\n")

    for i, vuln in enumerate(vulnerabilities, 1):
        content.append(f"### Finding {i}: {vuln.get('title', 'Unknown Vulnerability')}")
        content.append(f"- **Severity**: {vuln.get('severity', 'Unknown')}")
        content.append(f"- **Component**: {vuln.get('component', 'Unknown')}")
        content.append(f"- **Description**: {vuln.get('description', 'No description provided')}")

        if 'cve' in vuln:
            content.append(f"- **CVE**: {vuln['cve']}")

        if 'cvss_score' in vuln:
            content.append(f"- **CVSS Score**: {vuln['cvss_score']}")

        if 'location' in vuln:
            content.append(f"- **Location**: {vuln['location']}")

        content.append("")

    content.append("## Analysis Requirements\n")
    content.append("Please provide multi-perspective analysis including:")
    content.append("1. **Security Assessment**: Risk evaluation and severity validation")
    content.append("2. **Attack Scenarios**: Exploitation potential and threat modeling")
    content.append("3. **Compliance Impact**: Regulatory implications and standards compliance")
    content.append("4. **DevSecOps Remediation**: Practical implementation and code fixes")
    content.append("5. **Business Risk Analysis**: Strategic impact and resource planning")
    content.append("6. **Executive Summary**: Prioritized recommendations and next steps")

    return "\n".join(content)

def parse_sarif_input(sarif_file: Path) -> List[Dict]:
    """Parse SARIF format vulnerability data."""
    logger = logging.getLogger(__name__)

    try:
        with open(sarif_file, 'r', encoding='utf-8') as f:
            sarif_data = json.load(f)

        vulnerabilities = []

        for run in sarif_data.get('runs', []):
            for result in run.get('results', []):
                vuln = {
                    'title': result.get('message', {}).get('text', 'Unknown Vulnerability'),
                    'severity': result.get('level', 'info').upper(),
                    'description': result.get('message', {}).get('text', ''),
                    'rule_id': result.get('ruleId', ''),
                }

                # Extract location information
                locations = result.get('locations', [])
                if locations:
                    location = locations[0]
                    physical_location = location.get('physicalLocation', {})
                    artifact_location = physical_location.get('artifactLocation', {})
                    vuln['location'] = artifact_location.get('uri', 'Unknown')

                    # Add line number if available
                    region = physical_location.get('region', {})
                    if 'startLine' in region:
                        vuln['location'] += f":{region['startLine']}"

                # Extract CVE and CVSS if available
                properties = result.get('properties', {})
                if 'cve' in properties:
                    vuln['cve'] = properties['cve']
                if 'cvss_score' in properties:
                    vuln['cvss_score'] = properties['cvss_score']

                vulnerabilities.append(vuln)

        logger.info(f"Parsed {len(vulnerabilities)} vulnerabilities from SARIF file")
        return vulnerabilities

    except Exception as e:
        logger.error(f"Failed to parse SARIF file: {e}")
        return []

def run_enhanced_meeting_triage(input_content: str, output_file: Path) -> bool:
    """Run security triage using direct Ollama analysis."""
    logger = logging.getLogger(__name__)

    try:
        # Ensure output directory exists
        output_file.parent.mkdir(parents=True, exist_ok=True)

        logger.info("Starting enhanced security analysis...")

        # Create comprehensive analysis prompt
        analysis_prompt = f"""You are a cybersecurity expert conducting vulnerability triage. Analyze the following security vulnerabilities and provide a comprehensive assessment:

{input_content}

Please provide a structured analysis covering:

1. **Risk Assessment & Prioritization**
   - Severity classification for each vulnerability
   - CVSS scoring considerations
   - Business impact analysis
   - Exploitability assessment

2. **Technical Analysis**
   - Root cause analysis
   - Attack vectors and potential exploitation scenarios
   - Affected components and dependencies
   - Impact scope (confidentiality, integrity, availability)

3. **Remediation Strategy**
   - Immediate mitigation steps
   - Long-term fixes and code changes
   - Timeline recommendations (critical/high/medium/low)
   - Resource requirements

4. **Prevention Measures**
   - Code review process improvements
   - Security testing enhancements
   - Developer training recommendations
   - Process and policy improvements

5. **Communication Plan**
   - Stakeholder notification priorities
   - Status reporting schedule
   - Documentation requirements

Format your response as a professional security assessment report suitable for technical teams and management.
"""

        # Use Ollama API directly for analysis
        import requests
        import json

        ollama_url = "http://localhost:11434/api/generate"
        payload = {
            "model": "llama3.2:latest",
            "prompt": analysis_prompt,
            "stream": False
        }

        logger.info("Requesting security analysis from Ollama...")

        response = requests.post(ollama_url, json=payload, timeout=300)

        if response.status_code == 200:
            result = response.json()
            analysis_content = result.get('response', '')

            meeting_title = f"Security Vulnerability Triage - {datetime.now().strftime('%Y-%m-%d %H:%M')}"

            with open(output_file, 'w', encoding='utf-8') as f:
                f.write("# Security Vulnerability Triage Report\n\n")
                f.write(f"**Meeting Title:** {meeting_title}\n")
                f.write(f"**Generated:** {datetime.now().isoformat()}\n\n")
                f.write("## Security Analysis\n\n")
                f.write(analysis_content)

            logger.info(f"✅ Security triage completed: {output_file}")
            return True
        else:
            # Fallback: create basic report
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write("# Security Vulnerability Triage Report\n\n")
                f.write(f"**Generated:** {datetime.now().isoformat()}\n")
                f.write("**Status:** Ollama API failed\n\n")
                f.write("## Input Vulnerabilities\n\n")
                f.write(input_content)
                f.write("\n## Error Information\n\n")
                f.write(f"HTTP Status: {response.status_code}\n")
                f.write(f"Response: {response.text}\n")

            logger.warning(f"⚠️  Security triage completed with basic report: {output_file}")
            return True

    except Exception as e:
        logger.error(f"Security triage execution failed: {e}")

        # Create basic report even on error
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write("# Security Vulnerability Triage Report\n\n")
                f.write(f"**Generated:** {datetime.now().isoformat()}\n")
                f.write(f"**Status:** Analysis failed - {str(e)}\n\n")
                f.write("## Input Vulnerabilities\n\n")
                f.write(input_content)
        except Exception:
            pass

        return False


def main():
    """Main entry point for security triage system."""
    parser = argparse.ArgumentParser(description="Security Triage Multi-Agent System")
    parser.add_argument("--input", help="Input file (SARIF JSON or Markdown)")
    parser.add_argument("--output", help="Output markdown file (auto-generated if not specified)")
    parser.add_argument("--format", choices=["sarif", "markdown"], default="sarif",
                       help="Input format")
    parser.add_argument("--check-deps", action="store_true",
                       help="Check dependencies and exit")

    args = parser.parse_args()

    # Setup logging
    logger = setup_logging()
    logger.info("🛡️  Security Triage Multi-Agent System starting...")

    # Check dependencies
    if args.check_deps:
        if check_dependencies():
            print("✅ All dependencies available")
            sys.exit(0)
        else:
            print("❌ Missing dependencies")
            sys.exit(1)

    # Input is required for normal operation
    if not args.input:
        logger.error("Input file is required")
        parser.print_help()
        sys.exit(1)

    if not check_dependencies():
        logger.error("Missing required dependencies")
        sys.exit(1)    # Prepare input and output paths
    input_path = Path(args.input)
    if not input_path.exists():
        logger.error(f"Input file not found: {input_path}")
        sys.exit(1)

    if args.output:
        output_path = Path(args.output)
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = TRIAGE_OUTPUT_DIR / f"security_triage_{timestamp}.md"

    # Process input based on format
    if args.format == "sarif":
        logger.info("Parsing SARIF input...")
        vulnerabilities = parse_sarif_input(input_path)
        if not vulnerabilities:
            logger.error("No vulnerabilities found in SARIF file")
            sys.exit(1)

        # Create markdown input for enhanced meeting
        markdown_content = create_vulnerability_input(vulnerabilities)
    else:
        logger.info("Reading markdown input...")
        with open(input_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()

    # Run security triage using enhanced meeting
    logger.info("Starting multi-agent security triage...")
    if run_enhanced_meeting_triage(markdown_content, output_path):
        print(f"🎉 Security triage report generated: {output_path}")
        logger.info("✅ Security triage completed successfully")
    else:
        logger.error("❌ Security triage failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
