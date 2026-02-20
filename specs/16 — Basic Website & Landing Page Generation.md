A minimal but effective website generator for 1–10 person service businesses should standardize a small set of page/layout templates, a compact schema for business data, and opinionated integrations for GBP, CRM, and email hosting.

------

## 1. Minimum viable site structure

Core pages (required for all businesses):

1. Home

- Hero: H1 with primary keyword + city (e.g., “Plumbing Services in Madison, WI”), subtitle, primary CTA (Call / Request Quote), phone, service area line.
- Trust strip: badges (years in business, licenses, “Locally owned”), star rating summary, review count.
- Services overview: 3–8 service cards with title, 1–2 sentence description, “Learn more” links to service pages.
- Why choose us: 3–5 bullets (fast response, upfront pricing, etc.).
- Featured testimonials (2–4) with name, location, star rating.
- Service area snippet (list of key cities / neighborhoods).
- Final CTA block: “Call now / Book now / Request quote” plus short form.

1. Services index

- Intro paragraph targeting “{trade} services in {city}”.
- Grid/list of service pages with short descriptions and CTAs.
- Optional categories (e.g., Residential, Commercial).

1. Individual service pages (template)

- SEO H1: “{Service} in {City, ST}”.
- Short intro (problem + solution + who it’s for).
- “How it works” steps (3–5 steps).
- Bullet list of inclusions/benefits.
- Local social proof (testimonial or project snippet for that service).
- FAQ section (3–6 questions).
- Strong CTA section (call and form).

1. About

- Story (founder background, years in business, mission).
- Credentials (licenses, certifications, associations).
- Team highlight (optional; just names/roles).
- Service area reiteration and CTA.

1. Contact

- Contact form (name, email, phone, service requested, message, consent).
- Click-to-call phone, email, hours.
- Embedded Google Map, business address.
- Short “what happens after you contact us” explanation.

1. Testimonials / Reviews

- List view of testimonials with rating, name, location, service type.
- Optional “Leave a review” link to Google profile.

1. Service area / Locations (optional but recommended for SEO)

- H1: “Service Areas for {Business Name}”.
- Paragraph about coverage.
- Cards or simple list of cities/zip codes with short localized blurb (e.g., “Plumbing in Verona, WI”).

1. Privacy policy & Terms (boilerplate with business fields injected).

Each generated site can pick:

- 1 Home
- 1 Services index
- 3–10 service pages
- 1 About
- 1 Contact
- 1 Testimonials
- 1 Service area page
- 2 legal pages

→ 10–18 pages total, matching your target.

------

## 2. Content section templates (wire-level)

Define reusable **section** components the generator can assemble:

- HeroSection
  - fields: title, subtitle, primaryCtaText, primaryCtaType (call, formAnchor, link), secondaryCtaText, backgroundImageUrl, highlightBadges[].
- ServiceCardSection
  - fields: heading, introText, services[] (serviceId, label, shortDescription, icon, linkSlug).
- ProcessStepsSection
  - fields: heading, steps[] (title, description, icon, stepNumber).
- TestimonialsSection
  - fields: heading, testimonials[] (testimonialId, quote, name, location, rating, serviceName, source).
- FAQSection
  - fields: heading, faqs[] (question, answer, relatedServiceId).
- CTASection
  - fields: heading, body, primaryCtaText, primaryCtaType, phoneNumber, formAnchorId, backgroundStyle.
- ServiceAreaSection
  - fields: heading, introText, areas[] (city, state, zip, blurb).
- MapSection
  - fields: googleMapsEmbedUrl, addressText, directionsText.

These sections map cleanly to JSON and can be rendered in any frontend stack.

------

## 3. Data structures (JSON-level schemas)

You can store this in Postgres, Firestore, or similar with these conceptual schemas.

## 3.1 Business profile

```
json{
  "business_id": "uuid",
  "name": "string",
  "legal_name": "string",
  "tagline": "string",
  "description": "string",
  "industry": "string",
  "primary_service_category": "string",
  "founded_year": 2020,
  "employee_count": 6,
  "phone": "string",
  "mobile_phone": "string",
  "email": "string",
  "website_domain": "string",
  "address": {
    "line1": "string",
    "line2": "string",
    "city": "string",
    "state": "string",
    "postal_code": "string",
    "country": "string",
    "lat": 0,
    "lng": 0
  },
  "service_area_type": "single_location|multi_city|service_area",
  "service_areas": [
    {"city": "string", "state": "string", "postal_code": "string"}
  ],
  "hours": {
    "monday": {"open": "08:00", "close": "17:00", "closed": false},
    "tuesday": {"open": "08:00", "close": "17:00", "closed": false}
  },
  "licenses": [
    {"label": "string", "id_number": "string", "jurisdiction": "string"}
  ],
  "coverage_notes": "string",
  "primary_color": "string",
  "secondary_color": "string",
  "logo_url": "string",
  "brand_voice": "conversational|professional|friendly|formal",
  "google_business_profile": {
    "location_id": "string",
    "place_id": "string",
    "profile_url": "string"
  }
}
```

## 3.2 Services

```
json{
  "service_id": "uuid",
  "business_id": "uuid",
  "name": "string",
  "slug": "string",
  "category": "string",
  "short_description": "string",
  "detailed_description": "string",
  "typical_customers": "string",
  "starting_price": "number",
  "pricing_note": "string",
  "duration_estimate": "string",
  "is_featured": true,
  "seo": {
    "target_city": "string",
    "primary_keyword": "string",
    "secondary_keywords": ["string"],
    "meta_title": "string",
    "meta_description": "string"
  },
  "faqs": [
    {"question": "string", "answer": "string"}
  ]
}
```

## 3.3 Testimonials

```
json{
  "testimonial_id": "uuid",
  "business_id": "uuid",
  "source": "google|facebook|manual",
  "source_reference": "string",
  "customer_name": "string",
  "location_city": "string",
  "location_state": "string",
  "service_id": "uuid",
  "rating": 1,
  "headline": "string",
  "quote": "string",
  "date": "2025-11-01",
  "is_featured": true
}
```

## 3.4 Contact form submissions

```
json{
  "submission_id": "uuid",
  "business_id": "uuid",
  "timestamp": "2025-11-01T12:34:56Z",
  "source": "website_form",
  "page_slug": "water-heater-repair",
  "utm": {
    "source": "string",
    "medium": "string",
    "campaign": "string",
    "term": "string",
    "content": "string"
  },
  "contact": {
    "full_name": "string",
    "email": "string",
    "phone": "string",
    "preferred_contact_method": "phone|email|text"
  },
  "service_interest": "string",
  "message": "string",
  "consent": {
    "marketing_opt_in": true,
    "consent_text": "string"
  },
  "status": "new|pushed_to_crm|error",
  "crm_lead_id": "string"
}
```

------

## 4. Google Business Profile API integration

GBP API is used for synchronized NAP data, reviews, and posts to strengthen local SEO.

## 4.1 Access & auth (high level)

- Requirements:
  - Verified, active Business Profile 60+ days, complete with website URL.
  - Google Cloud project created, GBP API access requested and approved.
- Auth: OAuth 2.0; store refresh token encrypted per business.

## 4.2 Data flows

1. Sync core profile → website:

- On connection, call GBP endpoints to pull:
  - Business name, categories, address, phone, website, hours, description.
- Map to your BusinessProfile entity and let user confirm/edit before publishing.

1. Reviews import:

- Periodic job (e.g., daily) calls Reviews endpoint for location(s).
- Store mapped to Testimonials with source = “google”, show best 3–6 on site.

1. Posts & photos (optional):

- Expose a simple UI to post “What’s new” offers and photos via GBP Posts and media endpoints.

## 4.3 Architecture (simplified)

- Frontend: “Connect Google Business Profile” button → redirects to Google OAuth.
- Backend integration service:
  - Handles OAuth callback, stores tokens, calls GBP APIs.
  - Normalizes data into BusinessProfile/Testimonials tables.
  - Schedules sync jobs (e.g., via queue/cron).

------

## 5. Contact form → CRM lead pipeline

You already have/will have a lightweight CRM; wire the website generator to it.

## 5.1 Contact form template

Fields (front-end):

- Full name (required)
- Email (required or optional depending on business type)
- Phone (required for trades)
- How can we help? (dropdown of services + “Other”)
- Preferred contact method
- Free text message
- Optional: “How did you hear about us?”
- Consent checkbox (“I agree to be contacted...”).

## 5.2 Backend workflow

1. User submits form on /contact or service page.
2. Website backend:

- Validates, stores ContactFormSubmission (JSON above).
- Calls CRM API `/leads` with mapped data:
  - Lead: name, email, phone, source = “Website”, source_detail = page_slug, status = “New”.
  - Opportunity (optional): title “{Service} inquiry from website”, stage “Inquiry”.
  - Interaction: channel = “Web form”, summary = message.

1. CRM responds with lead_id/opportunity_id; you write back to submission record.
2. Trigger:

- Option A: CRM handles notifications and follow-ups.
- Option B: Website service also sends email to business’s Google Workspace inbox and optional SMS notification.

Integration is one-way from website → CRM for v1; no need to pull data back onto the site beyond basic analytics.

------

## 6. Hosting and Google Workspace compatibility

For 1–10 person shops, prioritize simple hosting that works with their Google Workspace domain.

- DNS & email:
  - Domain registrar: often Google Domains or others; MX points to Google Workspace.
  - A/AAAA or CNAME records point to your hosting (e.g., `www` CNAME → your static hosting).
- Hosting models:
  - Static frontends on platforms like Vercel/Netlify/cloud storage behind CDN; API backend on your own infra.
  - Or full-stack app (e.g., render.com, App Engine, Fly.io) with custom domain support.
- Requirements:
  - Free SSL via ACME.
  - Easy custom domain setup (CNAME for `www`, A record if apex).
  - Works with Google Workspace by leaving MX records untouched.

------

## 7. AI-generated website copy flow

Your generator should accept a short business description plus structured fields, then build page copy.

## 7.1 Input prompt structure

Collect from onboarding form:

- Business name, industry, location.
- Short free-text description (“We’re a 3-person plumbing team in Madison…”) similar to website copy generator tools.
- Services list with short internal descriptions.
- Brand voice (friendly / professional / luxury / casual).
- Target customers (homeowners, small offices, restaurants…).

## 7.2 Content generation per page

For each page, craft an internal instruction like:

- Home:
  - “Write a homepage for a small {industry} business in {city, state}. Include a strong headline with primary keyword, a short hero paragraph, 3–5 bullet benefits, brief service overview, 2 short testimonials (you will get real ones later), and a strong call-to-action.”
- Service pages:
  - “Write a service page for {service} in {city, state}. Include an intro, 3–5 bullet benefits, 3-step process, 3 FAQs, and a call-to-action. Use the brand voice: {brand_voice}.”
- About:
  - “Write an about page for a {size}-person company with this story: {free_text}. Mention years in business, local roots, and trustworthiness.”
- Contact:
  - “Write a brief contact page emphasizing fast response, clear pricing, and what happens after they submit the form.”

Align with copy generator best practices: include clear CTAs, benefits, FAQs, and adjust tone by voice parameter; allow user to edit generated copy before publishing.

Store generated content into the Page/Section models (e.g., hero.title, hero.subtitle, faq.answer).

------

## 8. Local SEO essentials baked into generator

For service businesses, you can auto-apply a base set of local SEO patterns.

Key elements:

- NAP consistency:
  - Use same business name, address, phone on Home, Contact, footer, and match GBP exactly.
- Keyword + location in:
  - Page titles and H1s (“{Service} in {City, ST}”).
  - Meta descriptions with benefit + CTA.
  - Service and service area pages.
- Dedicated pages:
  - Individual pages per key service; optional pages per major city/area.
- On-page elements:
  - Schema.org LocalBusiness/Service markup including address, phone, openingHours.
  - Embedded Google Map on contact page.
  - Internal linking:
    - Home → services → contact.
    - Service pages cross-link to related services and contact.
- Content strategy (for future blog extension):
  - Optional blog with local guides, FAQs, and case stories relevant to the area.
- Reviews:
  - Pull Google reviews and show them; link “Read more reviews on Google” to GBP profile.
- Performance basics:
  - Mobile-friendly layout and fast load times, as recommended for local SEO.

------

## 9. Integration architecture (high-level)

Conceptual components:

- Website Builder Backend
  - Manages BusinessProfile, Service, Testimonial, Page and Section schemas.
  - Stores AI-generated copy and user edits.
  - Exposes REST/GraphQL API for frontend rendering.
- Rendering Layer
  - Static site generator or SSR web app that consumes the API and builds public pages.
  - Deployment pipeline creates/updates site on publish.
- Integrations Service
  - GBP connector: OAuth handling, sync jobs.
  - CRM connector: pushes form submissions → CRM leads/opportunities.
  - Email notification service via SMTP or transactional provider.
- Public Site
  - Uses CDN hosting with custom domain integration; references business data via build-time fetch or server-side calls.

A simple diagram in your spec can show: Website Owner → Admin UI → Builder/AI → DB → Renderer → Static site → Visitor → Form → Backend → CRM + Email.

If you’d like, I can next turn this into more concrete Postgres table definitions and example REST endpoints for a specific stack.