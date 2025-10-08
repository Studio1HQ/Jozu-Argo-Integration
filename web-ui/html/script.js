document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('sentiment-form');
    const textInput = document.getElementById('text-input');
    const resultContainer = document.getElementById('result-container');
    const errorContainer = document.getElementById('error-container');
    const loadingContainer = document.getElementById('loading-container');
    const errorMessage = document.getElementById('error-message');
    
    const sentimentResult = document.getElementById('sentiment-result');
    const confidenceResult = document.getElementById('confidence-result');
    const positiveBar = document.getElementById('positive-bar');
    const negativeBar = document.getElementById('negative-bar');
    const positiveScore = document.getElementById('positive-score');
    const negativeScore = document.getElementById('negative-score');
    
    // Add event listeners for sample texts
    const sampleTexts = document.querySelectorAll('.sample-text');
    sampleTexts.forEach(button => {
        button.addEventListener('click', function() {
            textInput.value = this.textContent;
            // Optionally auto-submit
            // form.dispatchEvent(new Event('submit'));
        });
    });
    
    // Form submission
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const text = textInput.value.trim();
        if (!text) {
            showError('Please enter some text to analyze.');
            return;
        }
        
        // Show loading indicator
        hideAllContainers();
        loadingContainer.classList.remove('d-none');
        
        // Call the API
        analyzeSentiment(text);
    });
    
    function analyzeSentiment(text) {
        fetch('/api/predict', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ text: text })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            displayResults(data);
        })
        .catch(error => {
            showError('Error analyzing text: ' + error.message);
        });
    }
    
    function displayResults(data) {
        hideAllContainers();
        
        if (data.error) {
            showError(data.error);
            return;
        }
        
        // Display the results
        sentimentResult.textContent = data.prediction;
        confidenceResult.textContent = (data.confidence * 100).toFixed(2) + '%';
        
        // Update progress bars
        const positivePercentage = (data.probabilities.positive * 100).toFixed(2);
        const negativePercentage = (data.probabilities.negative * 100).toFixed(2);
        
        positiveBar.style.width = positivePercentage + '%';
        negativeBar.style.width = negativePercentage + '%';
        
        positiveScore.textContent = positivePercentage + '%';
        negativeScore.textContent = negativePercentage + '%';
        
        // Add appropriate styling based on sentiment
        if (data.prediction === 'positive') {
            sentimentResult.className = 'fw-bold text-success';
        } else {
            sentimentResult.className = 'fw-bold text-danger';
        }
        
        resultContainer.classList.remove('d-none');
    }
    
    function showError(message) {
        hideAllContainers();
        errorMessage.textContent = message;
        errorContainer.classList.remove('d-none');
    }
    
    function hideAllContainers() {
        resultContainer.classList.add('d-none');
        errorContainer.classList.add('d-none');
        loadingContainer.classList.add('d-none');
    }
});