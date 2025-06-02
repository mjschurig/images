import os

from marker.scripts.common import (
    load_models,
    parse_args,
    img_to_html,
    get_page_image,
    page_count,
)

os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
os.environ["IN_STREAMLIT"] = "true"

from marker.settings import settings
from streamlit.runtime.uploaded_file_manager import UploadedFile

import re
import tempfile
import json
import zipfile
import io
from typing import Any, Dict

import streamlit as st
from PIL import Image

from marker.converters.pdf import PdfConverter
from marker.config.parser import ConfigParser
from marker.output import text_from_rendered


def convert_pdf(fname: str, config_parser: ConfigParser) -> (str, Dict[str, Any], dict):
    config_dict = config_parser.generate_config_dict()
    config_dict["pdftext_workers"] = 1
    converter_cls = PdfConverter
    converter = converter_cls(
        config=config_dict,
        artifact_dict=model_dict,
        processor_list=config_parser.get_processors(),
        renderer=config_parser.get_renderer(),
        llm_service=config_parser.get_llm_service(),
    )
    return converter(fname)


def markdown_insert_images(markdown, images):
    image_tags = re.findall(
        r'(!\[(?P<image_title>[^\]]*)\]\((?P<image_path>[^\)"\s]+)\s*([^\)]*)\))',
        markdown,
    )

    for image in image_tags:
        image_markdown = image[0]
        image_alt = image[1]
        image_path = image[2]
        if image_path in images:
            markdown = markdown.replace(
                image_markdown, img_to_html(images[image_path], image_alt)
            )
    return markdown


def create_download_zip(text: str, images: dict, output_format: str, filename: str) -> bytes:
    """Create a ZIP file containing the converted text and images."""
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        # Add the main text file
        if output_format == "markdown":
            text_filename = f"{filename}.md"
        elif output_format == "json":
            text_filename = f"{filename}.json"
        elif output_format == "html":
            text_filename = f"{filename}.html"
        else:
            text_filename = f"{filename}.txt"
        
        zip_file.writestr(text_filename, text)
        
        # Add images if any
        for img_name, img_data in images.items():
            if isinstance(img_data, Image.Image):
                img_buffer = io.BytesIO()
                img_data.save(img_buffer, format='PNG')
                zip_file.writestr(f"images/{img_name}.png", img_buffer.getvalue())
            elif isinstance(img_data, bytes):
                zip_file.writestr(f"images/{img_name}", img_data)
    
    return zip_buffer.getvalue()


st.set_page_config(layout="wide")
col1, col2 = st.columns([0.5, 0.5])

model_dict = load_models()
cli_options = parse_args()

st.markdown("""
# Marker Demo

This app will let you try marker, a PDF or image -> Markdown, HTML, JSON converter. It works with any language, and extracts images, tables, equations, etc.

Find the project [here](https://github.com/VikParuchuri/marker).
""")

in_file: UploadedFile = st.sidebar.file_uploader(
    "PDF, document, or image file:",
    type=["pdf", "png", "jpg", "jpeg", "gif", "pptx", "docx", "xlsx", "html", "epub"],
)

if in_file is None:
    st.stop()

filetype = in_file.type

with col1:
    page_count = page_count(in_file)
    page_number = st.number_input(
        f"Page number out of {page_count}:", min_value=0, value=0, max_value=page_count
    )
    pil_image = get_page_image(in_file, page_number)
    st.image(pil_image, use_container_width=True)

page_range = st.sidebar.text_input(
    "Page range to parse, comma separated like 0,5-10,20",
    value=f"{page_number}-{page_number}",
)
output_format = st.sidebar.selectbox(
    "Output format", ["markdown", "json", "html"], index=0
)
run_marker = st.sidebar.button("Run Marker")

use_llm = st.sidebar.checkbox(
    "Use LLM", help="Use LLM for higher quality processing", value=False
)
force_ocr = st.sidebar.checkbox("Force OCR", help="Force OCR on all pages", value=False)
strip_existing_ocr = st.sidebar.checkbox(
    "Strip existing OCR",
    help="Strip existing OCR text from the PDF and re-OCR.",
    value=False,
)
debug = st.sidebar.checkbox("Debug", help="Show debug information", value=False)
format_lines = st.sidebar.checkbox(
    "Format lines",
    help="Format lines in the document with OCR model",
    value=False,
)
disable_ocr_math = st.sidebar.checkbox(
    "Disable math",
    help="Disable math in OCR output - no inline math",
    value=False,
)

if not run_marker:
    st.stop()

# Run Marker
with tempfile.TemporaryDirectory() as tmp_dir:
    temp_pdf = os.path.join(tmp_dir, "temp.pdf")
    with open(temp_pdf, "wb") as f:
        f.write(in_file.getvalue())

    cli_options.update(
        {
            "output_format": output_format,
            "page_range": page_range,
            "force_ocr": force_ocr,
            "debug": debug,
            "output_dir": settings.DEBUG_DATA_FOLDER if debug else None,
            "use_llm": use_llm,
            "strip_existing_ocr": strip_existing_ocr,
            "format_lines": format_lines,
            "disable_ocr_math": disable_ocr_math,
        }
    )
    config_parser = ConfigParser(cli_options)
    rendered = convert_pdf(temp_pdf, config_parser)
    page_range = config_parser.generate_config_dict()["page_range"]
    first_page = page_range[0] if page_range else 0

text, ext, images = text_from_rendered(rendered)

# Store conversion results in session state for download
if 'last_conversion' not in st.session_state:
    st.session_state.last_conversion = {}

st.session_state.last_conversion = {
    'text': text,
    'images': images,
    'output_format': output_format,
    'filename': in_file.name.rsplit('.', 1)[0] if '.' in in_file.name else in_file.name
}

with col2:
    if output_format == "markdown":
        text_for_display = markdown_insert_images(text, images)
        st.markdown(text_for_display, unsafe_allow_html=True)
    elif output_format == "json":
        st.json(text)
    elif output_format == "html":
        st.html(text)

# Add download section in sidebar
st.sidebar.markdown("---")
st.sidebar.markdown("### Download Results")

if 'last_conversion' in st.session_state and st.session_state.last_conversion:
    conversion_data = st.session_state.last_conversion
    
    # Download text file button
    if conversion_data['output_format'] == "markdown":
        file_ext = "md"
        mime_type = "text/markdown"
    elif conversion_data['output_format'] == "json":
        file_ext = "json"
        mime_type = "application/json"
    elif conversion_data['output_format'] == "html":
        file_ext = "html"
        mime_type = "text/html"
    else:
        file_ext = "txt"
        mime_type = "text/plain"
    
    # Convert text to string if it's not already
    text_data = conversion_data['text']
    if conversion_data['output_format'] == "json" and not isinstance(text_data, str):
        text_data = json.dumps(text_data, indent=2)
    
    st.sidebar.download_button(
        label=f"📄 Download {conversion_data['output_format'].upper()} file",
        data=text_data,
        file_name=f"{conversion_data['filename']}.{file_ext}",
        mime=mime_type,
        help=f"Download the converted {conversion_data['output_format']} file"
    )
    
    # Download ZIP with all files (text + images) if there are images
    if conversion_data['images']:
        zip_data = create_download_zip(
            text_data, 
            conversion_data['images'], 
            conversion_data['output_format'], 
            conversion_data['filename']
        )
        
        st.sidebar.download_button(
            label="📦 Download ZIP (text + images)",
            data=zip_data,
            file_name=f"{conversion_data['filename']}_complete.zip",
            mime="application/zip",
            help="Download a ZIP file containing the converted text and all extracted images"
        )
    
    # Display conversion info
    st.sidebar.info(f"**Format:** {conversion_data['output_format']}\n**Images:** {len(conversion_data['images'])} extracted")

if debug:
    with col1:
        debug_data_path = rendered.metadata.get("debug_data_path")
        if debug_data_path:
            pdf_image_path = os.path.join(debug_data_path, f"pdf_page_{first_page}.png")
            img = Image.open(pdf_image_path)
            st.image(img, caption="PDF debug image", use_container_width=True)
            layout_image_path = os.path.join(
                debug_data_path, f"layout_page_{first_page}.png"
            )
            img = Image.open(layout_image_path)
            st.image(img, caption="Layout debug image", use_container_width=True)
        st.write("Raw output:")
        st.code(text, language=output_format)
