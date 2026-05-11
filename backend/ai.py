import fitz
import pytesseract
from PIL import Image
import io
import json
import re
import requests

# ? [CONFIGURATION]
PDF_PATH = "backend/messy-sample.pdf"
OUTPUT_PATH = "backend/flashcards.json"

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "qwen3.5:9b"

# * [1] PDF Text Extraction
# ? [FUNCTION] Extract text from PDF page
def extract_text_from_page(page):
    return page.get_text().strip()

# ? [FUNCTION] Extract text using OCR (for scanned pages)
def extract_text_with_ocr(page):
    pix = page.get_pixmap(dpi=300)
    img_bytes = pix.tobytes("png")
    image = Image.open(io.BytesIO(img_bytes))
    return pytesseract.image_to_string(image).strip()

# ? [FUNCTION] Extract full PDF text (with OCR fallback)
def extract_pdf_text(pdf_path):
    doc = fitz.open(pdf_path)
    full_text = ""

    for i, page in enumerate(doc, start=1): # type: ignore
        print(f"Processing page {i}...")

        text = extract_text_from_page(page)

        if len(text.strip()) < 20:
            print("Using OCR fallback...")
            text = extract_text_with_ocr(page)

        full_text += text + "\n"

    doc.close()
    return full_text


# * [2] Text Cleaning
# ? [FUNCTION] Remove noise (headers, page numbers, junk lines)
def clean_text(text):
    lines = text.split("\n")
    cleaned = []

    for line in lines:
        line = line.strip()

        if not line:
            continue

        # remove page numbers
        if re.fullmatch(r"\d+", line):
            continue

        # remove "Page X of Y"
        if "page" in line.lower() and any(c.isdigit() for c in line):
            continue

        # remove very short noise
        if len(line) < 3:
            continue

        cleaned.append(line)

    return " ".join(cleaned)

# * [3] Text Chunking
# ? [FUNCTION] Split text into AI-safe chunks
def chunk_text(text, max_chars=2000):
    chunks = []
    current = ""

    # better sentence splitting
    sentences = re.split(r'(?<=[.!?]) +', text)

    for sentence in sentences:
        sentence = sentence.strip()

        if len(current) + len(sentence) < max_chars:
            current += sentence + " "
        else:
            chunks.append(current.strip())
            current = sentence + " "

    if current:
        chunks.append(current.strip())

    return chunks

# * [4] Local A.I. Processing (Ollama)
# ? [FUNCTION] Generate flashcards from text chunk using LLM
def generate_flashcards_with_ai(text_chunk):
    prompt = f"""
You are an expert teacher creating STUDY FLASHCARDS.

STRICT RULES:
- Only include IMPORTANT exam-worthy concepts
- Ignore examples unless they are essential
- Remove acronyms unless commonly used
- Do NOT create vague definitions
- Make definitions clear, specific, and accurate
- Prefer academic clarity over summarization

OUTPUT FORMAT:
[
  {{"term": "...", "definition": "..."}}
]

TEXT:
{text_chunk}
"""

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL,
            "prompt": prompt,
            "stream": False
        }
    )

    result = response.json()["response"]

    try:
        return json.loads(result)
    except:
        print("⚠️ JSON parse error, skipping chunk")
        return []


# * [5] Deduplication
# ? [FUNCTION] Remove duplicate flashcards by term
def deduplicate_flashcards(flashcards):
    seen = set()
    unique = []

    for card in flashcards:
        if "term" not in card:
            continue

        key = card["term"].lower().strip()

        if key not in seen:
            seen.add(key)
            unique.append(card)

    return unique


# * [6] Main Pipeline
print("\n========== EXTRACTING PDF ==========\n")
raw_text = extract_pdf_text(PDF_PATH)

print("\n========== CLEANING TEXT ==========\n")
cleaned_text = clean_text(raw_text)

print("\n========== CHUNKING TEXT ==========\n")
chunks = chunk_text(cleaned_text)

print(f"Total chunks: {len(chunks)}")

all_flashcards = []

print("\n========== OLLAMA PROCESSING ==========\n")

for i, chunk in enumerate(chunks, start=1):
    print(f"Processing chunk {i}/{len(chunks)}")

    cards = generate_flashcards_with_ai(chunk)
    all_flashcards.extend(cards)


print("\n========== DEDUPLICATING ==========\n")
final_flashcards = deduplicate_flashcards(all_flashcards)

print(f"Total flashcards: {len(final_flashcards)}")

print("\n========== RESULT PREVIEW ==========\n")
print(json.dumps(final_flashcards[:10], indent=2))

# * [7] Save Output (flashcards.json)
with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump(final_flashcards, f, indent=2, ensure_ascii=False)

print(f"\nSaved to {OUTPUT_PATH}")