-- Calculator Program
local CALCULATOR = {}

function CALCULATOR.GetContent()
    return [[
<div class="program-calculator">
    <div class="calculator-display">
        <div id="calculator-expression" class="calculator-expression"></div>
        <div id="calculator-result" class="calculator-result">0</div>
    </div>
    <div class="calculator-buttons">
        <button class="calc-btn calc-btn-clear" onclick="calculatorApp.clear()">C</button>
        <button class="calc-btn calc-btn-clear" onclick="calculatorApp.clearEntry()">CE</button>
        <button class="calc-btn calc-btn-op" onclick="calculatorApp.input('%')">%</button>
        <button class="calc-btn calc-btn-op" onclick="calculatorApp.input('÷')">÷</button>
        
        <button class="calc-btn" onclick="calculatorApp.input('7')">7</button>
        <button class="calc-btn" onclick="calculatorApp.input('8')">8</button>
        <button class="calc-btn" onclick="calculatorApp.input('9')">9</button>
        <button class="calc-btn calc-btn-op" onclick="calculatorApp.input('×')">×</button>
        
        <button class="calc-btn" onclick="calculatorApp.input('4')">4</button>
        <button class="calc-btn" onclick="calculatorApp.input('5')">5</button>
        <button class="calc-btn" onclick="calculatorApp.input('6')">6</button>
        <button class="calc-btn calc-btn-op" onclick="calculatorApp.input('-')">−</button>
        
        <button class="calc-btn" onclick="calculatorApp.input('1')">1</button>
        <button class="calc-btn" onclick="calculatorApp.input('2')">2</button>
        <button class="calc-btn" onclick="calculatorApp.input('3')">3</button>
        <button class="calc-btn calc-btn-op" onclick="calculatorApp.input('+')">+</button>
        
        <button class="calc-btn calc-btn-zero" onclick="calculatorApp.input('0')">0</button>
        <button class="calc-btn" onclick="calculatorApp.input('.')">.</button>
        <button class="calc-btn calc-btn-equals" onclick="calculatorApp.calculate()">=</button>
    </div>
</div>
]]
end

function CALCULATOR.GetInitScript()
    return [[
        calculatorApp.init(windowId);
    ]]
end

function CALCULATOR.GetJavaScript()
    return [[
var calculatorApp = {
    expression: '',
    result: '0',
    windowId: null,
    
    init: function(windowId) {
        this.windowId = windowId;
        this.updateDisplay();
    },
    
    input: function(value) {
        if (value === '.' && this.expression.includes('.')) {
            // Prevent multiple decimals in same number
            var parts = this.expression.split(/[\+\-\×\÷\%]/);
            if (parts.length > 0 && parts[parts.length - 1].includes('.')) {
                return;
            }
        }
        
        this.expression += value;
        this.updateDisplay();
    },
    
    clear: function() {
        this.expression = '';
        this.result = '0';
        this.updateDisplay();
    },
    
    clearEntry: function() {
        // Clear last entry
        if (this.expression.length > 0) {
            this.expression = this.expression.slice(0, -1);
            if (this.expression === '') {
                this.result = '0';
            }
            this.updateDisplay();
        }
    },
    
    calculate: function() {
        if (!this.expression) return;
        
        try {
            // Replace display symbols with JavaScript operators
            var expr = this.expression
                .replace(/×/g, '*')
                .replace(/÷/g, '/')
                .replace(/%/g, '/100*');
            
            // Evaluate safely
            var result = eval(expr);
            
            if (isNaN(result) || !isFinite(result)) {
                this.result = 'Error';
                this.expression = '';
            } else {
                this.result = result.toString();
                this.expression = '';
            }
        } catch (e) {
            this.result = 'Error';
            this.expression = '';
        }
        
        this.updateDisplay();
    },
    
    updateDisplay: function() {
        var exprElement = document.getElementById('calculator-expression');
        var resultElement = document.getElementById('calculator-result');
        
        if (exprElement) {
            exprElement.textContent = this.expression || '';
        }
        
        if (resultElement) {
            resultElement.textContent = this.result || '0';
        }
    }
};
]]
end

function CALCULATOR.GetCSS()
    return [[
.program-calculator {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: #1e1e1e;
}

.calculator-display {
    padding: 20px;
    background: #0d0d0d;
    border-bottom: 2px solid #333;
    min-height: 120px;
    display: flex;
    flex-direction: column;
    justify-content: flex-end;
    align-items: flex-end;
}

.calculator-expression {
    font-size: 18px;
    color: #888;
    margin-bottom: 8px;
    min-height: 24px;
    text-align: right;
    width: 100%;
    word-wrap: break-word;
}

.calculator-result {
    font-size: 36px;
    font-weight: bold;
    color: #ffffff;
    text-align: right;
    width: 100%;
    word-wrap: break-word;
    font-family: 'Courier New', monospace;
}

.calculator-buttons {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 2px;
    padding: 2px;
    flex: 1;
    background: #1e1e1e;
}

.calc-btn {
    background: #2d2d2d;
    border: 1px solid #444;
    color: #ffffff;
    font-size: 20px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.1s;
    outline: none;
    font-family: 'Segoe UI', sans-serif;
}

.calc-btn:hover {
    background: #3a3a3a;
    border-color: #555;
}

.calc-btn:active {
    background: #4a4a4a;
    transform: scale(0.95);
}

.calc-btn-op {
    background: #ff9500;
    border-color: #ff8500;
    color: #ffffff;
}

.calc-btn-op:hover {
    background: #ffaa33;
    border-color: #ff9500;
}

.calc-btn-op:active {
    background: #ff8800;
}

.calc-btn-clear {
    background: #505050;
    border-color: #666;
}

.calc-btn-clear:hover {
    background: #606060;
}

.calc-btn-equals {
    background: #ff9500;
    border-color: #ff8500;
    color: #ffffff;
}

.calc-btn-equals:hover {
    background: #ffaa33;
    border-color: #ff9500;
}

.calc-btn-zero {
    grid-column: span 2;
}
]]
end

return {
    title = "Calculator",
    icon = "🔢",
    width = 320,
    height = 480,
    getContent = CALCULATOR.GetContent,
    getInitScript = CALCULATOR.GetInitScript,
    getJavaScript = CALCULATOR.GetJavaScript,
    getCSS = CALCULATOR.GetCSS
}
