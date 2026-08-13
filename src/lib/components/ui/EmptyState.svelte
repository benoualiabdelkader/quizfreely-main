<script>
    /** 
     * @typedef {Object} Props
     * @property {string} title - The main heading
     * @property {string} [description] - Optional sub-text
     * @property {import('svelte').Snippet} [icon] - Icon slot
     * @property {import('svelte').Snippet} [action] - Action button slot
     */
    let { title, description = '', icon, action } = $props();
</script>

<div class="empty-state flex col center">
    {#if icon}
        <div class="icon-wrapper">
            {@render icon()}
        </div>
    {/if}
    
    <h3 class="title">{title}</h3>
    
    {#if description}
        <p class="description fg1">{description}</p>
    {/if}
    
    {#if action}
        <div class="action-wrapper">
            {@render action()}
        </div>
    {/if}
</div>

<style>
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: transparent;
        border-radius: var(--radius-xl, 16px);
        border: 2px dashed color-mix(in srgb, var(--fg-0) 10%, transparent);
        margin: 2rem 0;
    }
    
    .icon-wrapper {
        color: var(--fg-1);
        margin-bottom: 1.5rem;
        opacity: 0.7;
    }
    
    /* Ensure any SVG passed into icon gets sized reasonably by default */
    .icon-wrapper :global(svg) {
        width: 48px;
        height: 48px;
    }
    
    .title {
        margin: 0 0 0.5rem 0;
        font-size: 1.25rem;
        color: var(--fg-0);
    }
    
    .description {
        margin: 0;
        max-width: 400px;
        line-height: 1.5;
    }
    
    .action-wrapper {
        margin-top: 2rem;
    }
</style>
