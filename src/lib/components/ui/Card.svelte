<script>
    /** 
     * @typedef {Object} Props
     * @property {boolean} [interactive] - Adds hover styles if true
     * @property {string} [class] - Additional CSS classes
     * @property {import('svelte').Snippet} [children] - Content
     */
    let { interactive = false, class: className = '', children, ...props } = $props();
</script>

<div class="ui-card {interactive ? 'interactive' : ''} {className}" {...props}>
    {@render children?.()}
</div>

<style>
    .ui-card {
        background: var(--bg-1);
        border-radius: var(--radius-xl, 16px);
        padding: 1.5rem;
        border: 1px solid color-mix(in srgb, var(--fg-0) 5%, transparent);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
        transition: transform var(--transition-fast, 0.2s), box-shadow var(--transition-fast, 0.2s);
    }
    
    .ui-card.interactive {
        cursor: pointer;
    }
    
    .ui-card.interactive:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.15);
        border-color: color-mix(in srgb, var(--fg-0) 10%, transparent);
    }
</style>
