# isort . && black . && bandit -r . && pylint && pre-commit run --all-files
# Get changed files

FILES := $(wildcard **/*.py)

# if you wrap everything in poetry run, it runs slower.
ifeq ($(origin VIRTUAL_ENV),undefined)
    VENV := poetry run
else
    VENV :=
endif


clean-pyc:
	@echo "Removing compiled files"
	@find . -name '*.pyc' -exec rm -f {} + || true
	@find . -name '*.pyo' -exec rm -f {} + || true
	@find . -name '__pycache__' -exec rm -fr {} + || true

clean-test:
	@echo "Removing coverage data"
	@rm -f .coverage || true
	@rm -f .coverage.* || true

clean: clean-pyc clean-test

# tests can't be expected to pass if dependencies aren't installed.
# tests are often slow and linting is fast, so run tests on linted code.
test: clean pylint bandit
	@echo "Running unit tests"
	# $(VENV) pytest markdown-to-json --doctest-modules
	# $(VENV) python -m unittest discover
	$(VENV) py.test tests --cov-config=.coveragerc --cov=markdown_to_json --cov-report=html --cov-fail-under 88


isort:
	@echo "Formatting imports"
	$(VENV) isort markdown_to_json

.PHONY: isort

black: isort
	@echo "Formatting code"
	$(VENV) black . --exclude .virtualenv --exclude .tox

.PHONY: black

pre-commit: isort black
	@echo "Pre-commit checks"
	$(VENV) pre-commit run --all-files

.PHONY: pre-commit

bandit:
	@echo "Security checks"
	$(VENV)  bandit .

.PHONY: bandit

.PHONY: pylint
pylint: isort black
	@echo "Linting with pylint"
	# TODO lint tests
	$(VENV) pylint markdown_to_json --fail-under 9

.PHONY: ruff
ruff: isort black
	@echo "Linting with ruff"
	$(VENV) ruff markdown_to_json tests

.PHONY: ruff

# for when using -j (jobs, run in parallel)
.NOTPARALLEL: isort black

check: test pylint ruff bandit pre-commit

.PHONY: publish
publish: check
	rm -rf dist && poetry build
