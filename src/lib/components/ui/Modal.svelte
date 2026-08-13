<script>
    import { fade, scale } from "svelte/transition";
    import { onMount, onDestroy } from "svelte";

    /**
     * @typedef {Object} Props
     * @property {boolean} open - Controls visibility
     * @property {string} [title] - Optional title for accessibility and header
     * @property {Function} onClose - Callback when modal is closed
     * @property {import('svelte').Snippet} [children] - Modal content
     */
    let { open = false, title = '', onClose, children } = $props();

    function handleKeydown(e) {
        if (e.key === 'Escape' && open) {
            onClose();
        }
    }

    onMount(() => {
        window.addEventListener('keydown', handleKeydown);
    });

    onDestroy(() => {
        if (typeof window !== 'undefined') {
            window.removeEventListener('keydown', handleKeydown);
        }
    });
</script>

{#if open}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <div 
        class="modal-backdrop" 
        role="dialog" 
        aria-modal="true" 
        aria-label={title}
        transition:fade={{ duration: 150 }}
        onclick={onClose}
    >
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div 
            class="modal-content" 
            transition:scale={{ duration: 200, start: 0.95 }}
            onclick={(e) => e.stopPropagation()}
        >
            {#if title}
                <div class="modal-header">
                    <h2>{title}</h2>
                    <button class="close-btn" aria-label="Close modal" onclick={onClose}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                    </button>
                </div>
            {/if}
            
            <div class="modal-body">
                {@render children?.()}
            </div>
        </div>
    </div>
{/if}

<style>
    .modal-backdrop {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: color-mix(in srgb, var(--bg-0) 80%, transparent);
        backdrop-filter: blur(4px);
        -webkit-backdrop-filter: blur(4px);
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 1rem;
        box-sizing: border-box;
    }
    
    .modal-content {
        background: var(--bg-1);
        border-radius: var(--radius-xl, 16px);
        width: 100%;
        max-width: 500px;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 12px 48px rgba(0, 0, 0, 0.3);
        border: 1px solid color-mix(in srgb, var(--fg-0) 5%, transparent);
        display: flex;
        flex-direction: column;
    }
    
    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1.5rem 1.5rem 1rem;
        border-bottom: 1px solid color-mix(in srgb, var(--fg-0) 5%, transparent);
    }
    
    .modal-header h2 {
        margin: 0;
        font-size: 1.25rem;
    }
    
    .close-btn {
        background: transparent;
        border: none;
        color: var(--fg-1);
        cursor: pointer;
        padding: 0.25rem;
        border-radius: 8px;
        display: flex;
        transition: background 0.2s;
    }
    
    .close-btn:hover {
        background: var(--bg-2);
        color: var(--fg-0);
    }
    
    .modal-body {
        padding: 1.5rem;
    }
</style>
