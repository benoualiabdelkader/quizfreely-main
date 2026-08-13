<script>
    /** 
     * @typedef {Object} Props
     * @property {'primary' | 'secondary' | 'ghost' | 'destructive' | 'alt'} [variant] - Button style variant
     * @property {'sm' | 'md' | 'lg'} [size] - Button size
     * @property {string} [class] - Additional CSS classes
     * @property {import('svelte').Snippet} [children] - Content
     */
    let { variant = 'primary', size = 'md', class: className = '', children, ...props } = $props();
</script>

<button class="btn btn-{variant} btn-{size} {className}" {...props}>
    {@render children?.()}
</button>

<style>
    .btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        cursor: pointer;
        border: 2px solid transparent;
        transition: all var(--transition-fast, 0.2s);
        font-family: inherit;
        font-weight: 500;
        border-radius: var(--radius-lg, 12px);
        text-decoration: none;
    }
    
    .btn:active:not(:disabled) {
        transform: translateY(1px) scale(0.98);
    }
    
    .btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }
    
    /* Sizes */
    .btn-sm { padding: 0.5rem 0.75rem; font-size: 0.85rem; }
    .btn-md { padding: 0.75rem 1.25rem; font-size: 1rem; }
    .btn-lg { padding: 1rem 1.5rem; font-size: 1.1rem; height: 3.5rem; }
    
    /* Variants */
    .btn-primary {
        background: var(--main);
        color: #fff;
    }
    .btn-primary:hover:not(:disabled) {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px color-mix(in srgb, var(--main) 40%, transparent);
    }
    
    .btn-secondary, .btn-alt {
        background: var(--bg-1);
        color: var(--fg-0);
        border: 1px solid color-mix(in srgb, var(--fg-0) 10%, transparent);
    }
    .btn-secondary:hover:not(:disabled), .btn-alt:hover:not(:disabled) {
        background: var(--bg-2);
        border-color: color-mix(in srgb, var(--fg-0) 20%, transparent);
    }
    
    .btn-ghost {
        background: transparent;
        color: var(--fg-1);
    }
    .btn-ghost:hover:not(:disabled) {
        background: color-mix(in srgb, var(--fg-1) 15%, transparent);
        color: var(--fg-0);
    }
    
    .btn-destructive {
        background: color-mix(in srgb, var(--ohno, #FF5A5F) 15%, transparent);
        color: var(--ohno, #FF5A5F);
        border-color: transparent;
    }
    .btn-destructive:hover:not(:disabled) {
        background: var(--ohno, #FF5A5F);
        color: #fff;
        transform: translateY(-2px);
        box-shadow: 0 4px 12px color-mix(in srgb, var(--ohno, #FF5A5F) 40%, transparent);
    }
</style>
