-- =============================================================================
-- pilatGZ - Schema SQL Completo para Supabase
-- Academia de Pilates, Yoga e Bem-Estar - Aveiro, Portugal
-- =============================================================================
-- Este script cria toda a estrutura de base de dados necessária para o sistema
-- de autenticação, reservas e gestão da pilatGZ
-- =============================================================================

-- =============================================================================
-- 1. EXTENSÕES NECESSÁRIAS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 2. TABELA DE PERFIS DE UTILIZADORES
-- =============================================================================
-- Estende a tabela auth.users do Supabase com informações adicionais

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    birth_date DATE,
    avatar_url TEXT,
    bio TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    health_notes TEXT,
    newsletter_subscribed BOOLEAN DEFAULT FALSE,
    role VARCHAR(20) DEFAULT 'client' CHECK (role IN ('client', 'instructor', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Perfis de utilizadores estendidos para a pilatGZ';

-- =============================================================================
-- 3. TABELA DE MODALIDADES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.modalities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    short_description VARCHAR(255),
    benefits TEXT[],
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    max_participants INTEGER NOT NULL DEFAULT 10,
    intensity_level VARCHAR(20) CHECK (intensity_level IN ('low', 'medium', 'high')),
    image_url TEXT,
    icon_name VARCHAR(50),
    color VARCHAR(7) DEFAULT '#c5b8a5',
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.modalities IS 'Modalidades de aulas oferecidas (Pilates, Yoga, Barre, etc.)';

-- =============================================================================
-- 4. TABELA DE INSTRUTORES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.instructors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    bio TEXT,
    specialties TEXT[],
    certifications TEXT[],
    photo_url TEXT,
    email VARCHAR(255),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.instructors IS 'Instrutores e professores da academia';

-- =============================================================================
-- 5. TABELA DE HORÁRIOS DE AULAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.class_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    modality_id UUID NOT NULL REFERENCES public.modalities(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES public.instructors(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Domingo, 6=Sábado
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room VARCHAR(50),
    max_participants INTEGER NOT NULL DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.class_schedules IS 'Horários regulares das aulas';

-- =============================================================================
-- 6. TABELA DE AULAS ESPECÍFICAS (INSTÂNCIAS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES public.class_schedules(id) ON DELETE CASCADE,
    modality_id UUID NOT NULL REFERENCES public.modalities(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES public.instructors(id) ON DELETE CASCADE,
    class_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room VARCHAR(50),
    max_participants INTEGER NOT NULL DEFAULT 10,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled', 'completed')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.classes IS 'Instâncias específicas de aulas em datas concretas';

-- =============================================================================
-- 7. TABELA DE RESERVAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    reservation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'attended', 'no_show')),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    waitlist_position INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, class_id)
);

COMMENT ON TABLE public.reservations IS 'Reservas de aulas pelos utilizadores';

-- =============================================================================
-- 8. TABELA DE PLANOS/MEMBRESIAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.membership_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    classes_included INTEGER,
    validity_days INTEGER NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.membership_plans IS 'Planos de membresia disponíveis';

-- =============================================================================
-- 9. TABELA DE MEMBRESIAS DOS UTILIZADORES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES public.membership_plans(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    classes_remaining INTEGER,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.user_memberships IS 'Membresias ativas dos utilizadores';

-- =============================================================================
-- 10. TABELA DE EVENTOS/WORKSHOPS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) CHECK (event_type IN ('workshop', 'retreat', 'special_class', 'open_day')),
    instructor_id UUID REFERENCES public.instructors(id) ON DELETE SET NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(200),
    max_participants INTEGER,
    price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'EUR',
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    registration_open BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.events IS 'Eventos especiais, workshops e retiros';

-- =============================================================================
-- 11. TABELA DE INSCRIÇÕES EM EVENTOS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.event_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'registered' CHECK (status IN ('registered', 'cancelled', 'attended')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, event_id)
);

COMMENT ON TABLE public.event_registrations IS 'Inscrições dos utilizadores nos eventos';

-- =============================================================================
-- 12. TABELA DE CONTACTOS/FORMULÁRIO
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.contact_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    subject VARCHAR(200),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    responded_at TIMESTAMP WITH TIME ZONE,
    response_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.contact_messages IS 'Mensagens recebidas através do formulário de contacto';

-- =============================================================================
-- 13. TABELA DE NOTIFICAÇÕES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) CHECK (type IN ('reservation', 'cancellation', 'reminder', 'promotion', 'system')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Notificações para os utilizadores';

-- =============================================================================
-- 14. TABELA DE AVALIAÇÕES/REVIEWS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL,
    instructor_id UUID REFERENCES public.instructors(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.reviews IS 'Avaliações e comentários dos alunos';

-- =============================================================================
-- 15. ÍNDICES PARA PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);

CREATE INDEX IF NOT EXISTS idx_class_schedules_modality ON public.class_schedules(modality_id);
CREATE INDEX IF NOT EXISTS idx_class_schedules_instructor ON public.class_schedules(instructor_id);
CREATE INDEX IF NOT EXISTS idx_class_schedules_day ON public.class_schedules(day_of_week);

CREATE INDEX IF NOT EXISTS idx_classes_date ON public.classes(class_date);
CREATE INDEX IF NOT EXISTS idx_classes_status ON public.classes(status);
CREATE INDEX IF NOT EXISTS idx_classes_schedule ON public.classes(schedule_id);

CREATE INDEX IF NOT EXISTS idx_reservations_user ON public.reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_class ON public.reservations(class_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON public.reservations(status);

CREATE INDEX IF NOT EXISTS idx_user_memberships_user ON public.user_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_user_memberships_status ON public.user_memberships(status);

CREATE INDEX IF NOT EXISTS idx_event_registrations_user ON public.event_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_event ON public.event_registrations(event_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);

-- =============================================================================
-- 16. FUNÇÕES AUXILIARES
-- =============================================================================

-- Função para atualizar o updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar disponibilidade de uma aula
CREATE OR REPLACE FUNCTION public.check_class_availability(class_uuid UUID)
RETURNS TABLE (
    total_slots INTEGER,
    booked_slots INTEGER,
    available_slots INTEGER,
    is_full BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.max_participants::INTEGER as total_slots,
        COUNT(r.id)::INTEGER as booked_slots,
        (c.max_participants - COUNT(r.id))::INTEGER as available_slots,
        (COUNT(r.id) >= c.max_participants) as is_full
    FROM public.classes c
    LEFT JOIN public.reservations r ON r.class_id = c.id AND r.status = 'confirmed'
    WHERE c.id = class_uuid
    GROUP BY c.max_participants;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para criar notificação
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_title VARCHAR,
    p_message TEXT,
    p_type VARCHAR DEFAULT 'system'
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (p_user_id, p_title, p_message, p_type)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para cancelar reserva
CREATE OR REPLACE FUNCTION public.cancel_reservation(
    p_reservation_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_class_id UUID;
BEGIN
    SELECT user_id, class_id INTO v_user_id, v_class_id
    FROM public.reservations
    WHERE id = p_reservation_id;
    
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    UPDATE public.reservations
    SET 
        status = 'cancelled',
        cancelled_at = NOW(),
        cancellation_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_reservation_id;
    
    -- Criar notificação de cancelamento
    PERFORM public.create_notification(
        v_user_id,
        'Reserva Cancelada',
        'A sua reserva foi cancelada com sucesso.',
        'cancellation'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 17. TRIGGERS
-- =============================================================================

-- Triggers para atualizar updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_modalities_updated_at
    BEFORE UPDATE ON public.modalities
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_instructors_updated_at
    BEFORE UPDATE ON public.instructors
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_class_schedules_updated_at
    BEFORE UPDATE ON public.class_schedules
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_classes_updated_at
    BEFORE UPDATE ON public.classes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reservations_updated_at
    BEFORE UPDATE ON public.reservations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_membership_plans_updated_at
    BEFORE UPDATE ON public.membership_plans
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_memberships_updated_at
    BEFORE UPDATE ON public.user_memberships
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON public.events
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_event_registrations_updated_at
    BEFORE UPDATE ON public.event_registrations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger para criar perfil após registro
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, first_name, last_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        'client'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger para notificar nova reserva
CREATE OR REPLACE FUNCTION public.handle_new_reservation()
RETURNS TRIGGER AS $$
DECLARE
    v_class_info TEXT;
BEGIN
    SELECT CONCAT(m.name, ' - ', c.class_date, ' ', c.start_time)
    INTO v_class_info
    FROM public.classes c
    JOIN public.modalities m ON m.id = c.modality_id
    WHERE c.id = NEW.class_id;
    
    PERFORM public.create_notification(
        NEW.user_id,
        'Reserva Confirmada',
        CONCAT('A sua reserva para ', v_class_info, ' foi confirmada.'),
        'reservation'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_reservation_created
    AFTER INSERT ON public.reservations
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_reservation();

-- =============================================================================
-- 18. POLÍTICAS RLS (ROW LEVEL SECURITY)
-- =============================================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.membership_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Políticas para profiles
CREATE POLICY "Profiles são visíveis para todos autenticados"
    ON public.profiles FOR SELECT
    TO authenticated USING (true);

CREATE POLICY "Utilizadores podem ver o próprio perfil"
    ON public.profiles FOR SELECT
    TO anon USING (false);

CREATE POLICY "Utilizadores podem editar o próprio perfil"
    ON public.profiles FOR UPDATE
    TO authenticated USING (auth.uid() = id);

CREATE POLICY "Admins podem gerir todos os perfis"
    ON public.profiles FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para modalities
CREATE POLICY "Modalidades são visíveis para todos"
    ON public.modalities FOR SELECT
    TO anon, authenticated USING (is_active = true);

CREATE POLICY "Admins podem gerir modalidades"
    ON public.modalities FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para instructors
CREATE POLICY "Instrutores são visíveis para todos"
    ON public.instructors FOR SELECT
    TO anon, authenticated USING (is_active = true);

CREATE POLICY "Admins podem gerir instrutores"
    ON public.instructors FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para class_schedules
CREATE POLICY "Horários são visíveis para todos"
    ON public.class_schedules FOR SELECT
    TO anon, authenticated USING (is_active = true);

CREATE POLICY "Admins podem gerir horários"
    ON public.class_schedules FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para classes
CREATE POLICY "Aulas são visíveis para todos"
    ON public.classes FOR SELECT
    TO anon, authenticated USING (status != 'cancelled');

CREATE POLICY "Admins podem gerir aulas"
    ON public.classes FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para reservations
CREATE POLICY "Utilizadores podem ver as próprias reservas"
    ON public.reservations FOR SELECT
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Utilizadores podem criar reservas"
    ON public.reservations FOR INSERT
    TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Utilizadores podem cancelar as próprias reservas"
    ON public.reservations FOR UPDATE
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Admins podem ver todas as reservas"
    ON public.reservations FOR SELECT
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para membership_plans
CREATE POLICY "Planos são visíveis para todos"
    ON public.membership_plans FOR SELECT
    TO anon, authenticated USING (is_active = true);

CREATE POLICY "Admins podem gerir planos"
    ON public.membership_plans FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para user_memberships
CREATE POLICY "Utilizadores podem ver as próprias membresias"
    ON public.user_memberships FOR SELECT
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Admins podem gerir todas as membresias"
    ON public.user_memberships FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para events
CREATE POLICY "Eventos são visíveis para todos"
    ON public.events FOR SELECT
    TO anon, authenticated USING (is_active = true);

CREATE POLICY "Admins podem gerir eventos"
    ON public.events FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para event_registrations
CREATE POLICY "Utilizadores podem ver as próprias inscrições"
    ON public.event_registrations FOR SELECT
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Utilizadores podem inscrever-se em eventos"
    ON public.event_registrations FOR INSERT
    TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins podem gerir todas as inscrições"
    ON public.event_registrations FOR ALL
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para contact_messages
CREATE POLICY "Qualquer um pode enviar mensagens"
    ON public.contact_messages FOR INSERT
    TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Apenas admins podem ver mensagens"
    ON public.contact_messages FOR SELECT
    TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Políticas para notifications
CREATE POLICY "Utilizadores podem ver as próprias notificações"
    ON public.notifications FOR SELECT
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Utilizadores podem marcar notificações como lidas"
    ON public.notifications FOR UPDATE
    TO authenticated USING (user_id = auth.uid());

-- Políticas para reviews
CREATE POLICY "Reviews aprovadas são visíveis para todos"
    ON public.reviews FOR SELECT
    TO anon, authenticated USING (is_approved = true);

CREATE POLICY "Utilizadores podem ver as próprias reviews"
    ON public.reviews FOR SELECT
    TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Utilizadores podem criar reviews"
    ON public.reviews FOR INSERT
    TO authenticated WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 19. DADOS INICIAIS (SEED)
-- =============================================================================

-- Inserir modalidades
INSERT INTO public.modalities (name, slug, description, short_description, benefits, duration_minutes, max_participants, intensity_level, color, display_order)
VALUES 
    ('Pilates Mat', 'pilates-mat', 
     'Pilates em mat é uma forma de exercício que enfatiza o fortalecimento do core, a melhoria da postura e o desenvolvimento de um corpo longo e tonificado. Utilizando apenas o peso do corpo e pequenos equipamentos, as aulas focam no controle, precisão e respiração consciente.', 
     'Fortaleça o core e melhore a postura',
     ARRAY['Fortalecimento do core', 'Melhoria da postura', 'Aumento da flexibilidade', 'Redução do stress', 'Prevenção de lesões'],
     60, 12, 'medium', '#c5b8a5', 1),
    
    ('Yoga Flow', 'yoga-flow', 
     'Yoga Flow é uma prática dinâmica que conecta movimento e respiração numa sequência fluida de posturas. Ideal para quem procura energia, força e flexibilidade, esta modalidade promove o bem-estar físico e mental através de uma prática consciente e fluida.', 
     'Movimento fluido em sintonia com a respiração',
     ARRAY['Aumento da flexibilidade', 'Fortalecimento muscular', 'Redução do stress', 'Melhoria do foco', 'Equilíbrio emocional'],
     60, 15, 'medium', '#a89f91', 2),
    
    ('Yoga Restore', 'yoga-restore', 
     'Yoga Restore é uma prática suave e terapêutica que utiliza apoios para permitir que o corpo se relaxe profundamente em cada postura. Focada na recuperação e no relaxamento, é ideal para aliviar o stress, a tensão muscular e promover um sono melhor.', 
     'Relaxamento profundo e recuperação',
     ARRAY['Relaxamento profundo', 'Redução da ansiedade', 'Melhoria do sono', 'Recuperação muscular', 'Calma mental'],
     75, 10, 'low', '#d4ccc0', 3),
    
    ('Barre', 'barre', 
     'Barre é uma fusão de ballet, pilates e yoga que cria um treino de baixo impacto mas de alta intensidade. Utilizando a barra como apoio, as aulas focam no fortalecimento, tonificação e alongamento dos músculos, criando um corpo longo e elegante.', 
     'Fusão de ballet, pilates e yoga',
     ARRAY['Tonificação muscular', 'Melhoria da postura', 'Aumento da flexibilidade', 'Fortalecimento do core', 'Coordenação e equilíbrio'],
     60, 12, 'high', '#b8a895', 4);

-- Inserir planos de membresia
INSERT INTO public.membership_plans (name, description, price, validity_days, classes_included, is_recurring, display_order)
VALUES 
    ('Aula Avulsa', 'Uma aula de experimentação ou ocasional', 15.00, 30, 1, FALSE, 1),
    ('Pack 5 Aulas', 'Pack de 5 aulas válido por 3 meses', 65.00, 90, 5, FALSE, 2),
    ('Pack 10 Aulas', 'Pack de 10 aulas válido por 3 meses', 120.00, 90, 10, FALSE, 3),
    ('Mensalidade Ilimitada', 'Aulas ilimitadas durante 1 mês', 85.00, 30, NULL, TRUE, 4);

-- =============================================================================
-- 20. PERMISSÕES ADICIONAIS
-- =============================================================================

-- Permitir que utilizadores autenticados acessem funções
GRANT EXECUTE ON FUNCTION public.check_class_availability TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_reservation TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_notification TO authenticated;

-- =============================================================================
-- FIM DO SCHEMA
-- =============================================================================
