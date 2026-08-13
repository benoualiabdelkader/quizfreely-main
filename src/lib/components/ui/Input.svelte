<script>
    /** 
     * @typedef {Object} Props
     * @property {string} [type] - Input type (text, password, email)
     * @property {string} [class] - Additional CSS classes
     */
    let { type = 'text', class: className = '', ...props } = $props();
</script>

<input {type} class="ui-input {className}" {...props} />

<style>
    .ui-input {
        background: var(--bg-1);
        border: 1px solid color-mix(in srgb, var(--fg-0) 15%, transparent);
        border-radius: var(--radius-lg, 12px);
        transition: all var(--transition-fast, 0.2s);
        color: var(--fg-0);
        padding: 0.75rem 1rem;
        font-family: inherit;
        font-size: 1rem;
        width: 100%;
        box-sizing: border-box;
    }
    
    .ui-input:focus {
        outline: none;
        border-color: var(--main);
        box-shadow: 0 0 0 3px color-mix(in srgb, var(--main) 20%, transparent);
        background: color-mix(in srgb, var(--bg-1) 80%, var(--bg-2));
    }
    
    .ui-input::placeholder {
        color: var(--fg-1);
        opacity: 0.7;
    }
    
    .ui-input:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }
</style>
