<script>
  import { env } from "$env/dynamic/public";
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { slide } from "svelte/transition";
  import Noscript from "$lib/components/Noscript.svelte";
  import Card from "$lib/components/ui/Card.svelte";
  import Input from "$lib/components/ui/Input.svelte";
  import Button from "$lib/components/ui/Button.svelte";

  let { data } = $props();

  let showErr = $state(false);
  let errMsg = $state("");
  let signinPasswordValue = $state("");
  let signinUsernameValue = $state("");

      function signinSubmit() {
        fetch("/api/v0/auth/sign-in", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            username: signinUsernameValue,
            password: signinPasswordValue,
          }),
        })
          .then(function (rawResponse) {
            rawResponse
              .json()
              .then(function (response) {
                if (response.error) {
                  console.log("error in response: ", response);
                  showErr = true;
                  if (response.error.message != null) {
                    errMsg = response.error.message;
                  } else if (response.error.code != null) {
                    errMsg = "<b>Error</b>: " + response.error.code;
                  } else {
                    errMsg = "idk something went wrong sorry :(";
                  }
                } else {
                  goto("/dashboard");
                  // window.location.reload();
                }
              })
              .catch(function (error) {
                console.error(error);
                showErr = true;
                errMsg = "Error: Can't connect for some reason <b>:(</b>";
              });
          })
          .catch(function (error) {
            console.error(error);
            showErr = true;
            errMsg = "Error: Can't connect for some reason <b>:(</b>";
          });
      }

  onMount(function () {
    if (!data.authed) {
      if (window.location.search.includes("?error")) {
        var urlParams = new URLSearchParams(window.location.search);
        showErr = true;
        errMsg = "<b>Error</b>: " + urlParams.get("error");
      }

    }
  });
</script>

<svelte:head>
  <title>Sign in - Quizfreely</title>
  <meta
    name="description"
    content="Quizfreely is a free and open source studying tool."
  />
</svelte:head>

<Noscript />
<main>
  {#if showErr}
    <div class="grid page" transition:slide={{ duration: 400 }}>
      <div class="content">
        <div class="box ohno">
          <p>{@html errMsg}</p>
        </div>
      </div>
    </div>
  {/if}
  {#if data.authed}
    <div class="grid thin-centered">
      <Card style="margin-top: 6rem; text-align: center;">
        <p class="h3">You're signed in!</p>
        <div class="flex center-h" style="gap: 1rem; margin-top: 1.5rem;">
          <a href="/dashboard" style="text-decoration: none;"><Button variant="primary">Dashboard</Button></a>
          <a href="/settings" style="text-decoration: none;"><Button variant="secondary">Settings</Button></a>
        </div>
      </Card>
    </div>
  {:else}
    <div>
      <div class="grid thin-centered">
        <Card>
          <h2 style="margin-top: 0;">Sign In</h2>
          <form onsubmit={(ev) => {
              ev.preventDefault();
              signinSubmit();
          }}>
          <div style="margin-bottom: 1rem;">
            <Input
              type="text"
              bind:value={signinUsernameValue}
              placeholder="Username"
              name="username"
              autocomplete="username"
            />
          </div>
          <div style="margin-bottom: 1.5rem;">
            <Input
              type="password"
              bind:value={signinPasswordValue}
              placeholder="Password"
              name="password"
              autocomplete="current-password"
            />
          </div>
          <div>
            <Button variant="primary" type="submit" style="width: 100%;">Sign in</Button>
          </div>
          </form>
          <div class="separator">or</div>
          <div>
            {#if env.ENABLE_OAUTH_GOOGLE == "true"}
              <a
                class="button fullWidth gaccount-button no-box-shadow"
                href="/api/oauth/google"
              >
                <div class="gaccount-container">
                  <div class="gaccount-icon">
                    <svg
                      version="1.1"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 48 48"
                      xmlns:xlink="http://www.w3.org/1999/xlink"
                      style="display: block;"
                    >
                      <path
                        fill="#EA4335"
                        d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
                      ></path>
                      <path
                        fill="#4285F4"
                        d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
                      ></path>
                      <path
                        fill="#FBBC05"
                        d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
                      ></path>
                      <path
                        fill="#34A853"
                        d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
                      ></path>
                      <path fill="none" d="M0 0h48v48H0z"></path>
                    </svg>
                  </div>
                  <div>Sign in with Google</div>
                </div>
              </a>
            {/if}
          </div>
          <div>
            <Button
              variant="ghost"
              style="width: 100%; margin-top: 1rem;"
              onclick={async () => {
                await fetch("/dashboard/set-dashboard-state", {
                  method: "POST",
                  credentials: "include",
                });
                goto("/dashboard");
              }}
            >
              Continue without an account
            </Button>
          </div>
        </Card>
      </div>
      <div class="grid thin-centered" style="margin-top: 1rem;">
        <div style="text-align: center;">
          <p><a href="./sign-up">Sign up</a> to create an account</p>
        </div>
      </div>
    </div>
  {/if}
</main>

<style>
  .button.gaccount-button {
    background-color: #fefefe;
    color: #1f1f1f;
    font-family: Roboto, Inter, Arial, Helvetica, sans-serif;
    border: 0.2rem solid var(--border);
    border-radius: 2rem;
    padding: 0.6rem;
  }
  .button.gaccount-button:hover,
  .button.gaccount-button:focus,
  .button.gaccount-button:focus-visible {
    background-color: #f0f0f0;
    color: #1f1f1f;
  }

  .button.gaccount-button div.gaccount-container {
    display: flex;
    gap: 1rem;
    align-items: center;
    align-content: center;
    justify-items: center;
    justify-content: center;
  }

  .button.gaccount-button div.gaccount-container div {
    margin-top: 0px;
  }

  .gaccount-icon {
    width: 1.4rem;
    height: 1.4rem;
  }

  button.noaccount-button,
  .button.noaccount-button {
    padding: 0.6rem 0.8rem;
    margin-bottom: 1rem;
  }
</style>
