Frequent terminal codes:

#Update Dependencies
pip freeze > requirements.txt

#Run Code
python3 student-data-pipeline-portfolio/python/{file name}
quarto render student-data-pipeline-portfolio/python/{file name}

#Activate Virtual Environment
source .venv/bin/activate

#Python Enviornment
python -m venv .venv
source .venv/bin/python  # Mac/Linux
pip install -r requirements.txt

#R Enviornment
Rscript install.R


