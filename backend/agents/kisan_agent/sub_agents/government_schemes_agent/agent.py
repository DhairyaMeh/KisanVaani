import os
import jinja2

from google.adk.agents import Agent
from dotenv import load_dotenv
from google.adk.tools.agent_tool import AgentTool
from google.adk.tools import google_search
from agents.kisan_agent.sub_agents.government_schemes_agent import prompt

# Import Qdrant RAG tool
try:
    from agents.kisan_agent.sub_agents.government_schemes_agent.qdrant_rag_tool import qdrant_rag_tool
    QDRANT_AVAILABLE = True
except ImportError:
    QDRANT_AVAILABLE = False
    print("Warning: Qdrant RAG tool not available. Using Google Search only.")


this_dir = os.path.dirname(os.path.abspath(__file__))
prompt_template_path = os.path.join(this_dir, "prompt_templates")
prompt_template_loader = jinja2.FileSystemLoader(prompt_template_path)
jinja2_env = jinja2.Environment(loader=prompt_template_loader)

def get_prompt_template(template_name: str):
        preferred_template_filename = (
            f"{template_name}.jinja2"
        )
        return jinja2_env.get_template(preferred_template_filename)

rag_retrieval_agent_prompt = """
You are an AI assistant specialized in retrieving information about government agricultural schemes from a knowledge base.

Your task is to:
1. Use the retrieve_government_schemes tool to search for relevant scheme information
2. Analyze and summarize the retrieved information
3. Present the information clearly with source references

When searching, be specific with your queries. For example:
- "PM Kisan scheme eligibility and benefits"
- "Karnataka state agricultural subsidies"
- "Organic farming incentives India"

Always cite the source documents when providing information.
"""

# --- Google Search Agent ---
search_agent = Agent(
    name="google_search_agent",
    model="gemini-2.0-flash",
    description="Agent to answer questions using Google Search related to farmer agricultural scheme queries.",
    instruction=prompt.google_search_prompt,
    tools=[google_search]
)

# --- RAG Agent (using Qdrant) ---
rag_agent = None
if QDRANT_AVAILABLE:
    rag_agent = Agent(
        model='gemini-2.5-flash',
        name='qdrant_rag_agent',
        description="An agent that answers questions about agricultural government schemes using the Qdrant vector database corpus.",
        instruction=rag_retrieval_agent_prompt,
        tools=[qdrant_rag_tool]
    )

# --- Main Agent ---
# Build tools list based on availability
main_agent_tools = [AgentTool(agent=search_agent)]
if rag_agent:
    main_agent_tools.append(AgentTool(agent=rag_agent))

scheme_agent = Agent(
    model='gemini-2.5-flash',
    name="Govt_Agricultural_Scheme_Agent", 
    description="This is the main government scheme retriever agent that provides the final information (with portal links) from both google search and RAG retriever tools.",
    instruction="""
        You are an AI assistant that is the main government scheme retriever agent. Your task is to provide the final information on user query from both google search and RAG retriever tools.
        
        IMPORTANT: Always try BOTH tools when available:
        1. Use the qdrant_rag_agent to search the local knowledge base for scheme documentation
        2. Use the google_search_agent for recent updates and additional information
        
        Understand the responses from both tools and provide a concise answer that includes all relevant information. 
        Make sure to include the relevant scheme portal links received from the two tools. In case there is no link provided, give the default link as: "https://raitamitra.karnataka.gov.in/english".
        WHILE SUMMARIZING THE RESPONSE, MAKE SURE to keep all the provided links by the two tools AT THE END OF THE RESPONSE. ONLY ADD THE DEFAULT LINK IF NO SPECIFIC LINK WAS PROVIDED.
        DO NOT add in the response that no specific link was provided, just give the default link.

        Summarize the final answer in 500-600 words (make sure to always include links in the response). If the user asks to go in more detail, only then provide the detailed answer.
        """,
    tools=main_agent_tools)
 